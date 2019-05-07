module QBWC
  module Response
    class ItemInventoryQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying products'),
                                           'products',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }
        product_params = receive_configs.find { |c| c['products'] }

        if inventory_params
          payload = { inventories: inventories_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling
        end

        if product_params
          payload = { products: products_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}
          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          product_params['products']['quickbooks_since'] = last_time_modified
          product_params['products']['quickbooks_force_config'] = true

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = product_params['products']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config = config.merge(origin: 'flowlink')
        object_persistence = Persistence::Object.new config
        object_persistence.update_objects_with_query_results(objects_to_update)

        nil
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      private

      def objects_to_update
        records.map do |record|
          {
            object_type: 'product',
            object_ref: (record['ParentRef'].is_a?(Array) ? record['ParentRef'] : (record['ParentRef'].nil? ? [] : [record['ParentRef']])).map { |item| item['FullName'] + ':' }.join('') + record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def inventories_to_flowlink
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            quantity: record['QuantityOnHand'],
            grabbed_at: Time.now.to_s
          }
        end
      end

      def products_to_flowlink
        puts "Product object from QBE: #{records.first}"
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            fullname: record['FullName'],
            quantity: record['QuantityOnHand'],
            is_active: record['IsActive'],
            unit_measure: record.dig('UnitOfMeasureSetRef', 'FullName'),
            sales_price: record['SalesPrice'],
            purchase_description: record['PurchaseDesc'],
            purchase_cost: record['PurchaseCost'],
            vendor_name: record.dig('PrefVendorRef', 'FullName'),
            average_cost: record['AverageCost'],
            quantity_on_order: record['QuantityOnOrder'],
            quantity_on_sales_order: record['QuantityOnSalesOrder']
          }

          object
        end
      end
    end
  end
end
