module QBWC
  module Response
    class ItemSalesTaxQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying sales tax products'),
                                           'salestaxproducts',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        puts({connection_id: config[:connection_id], method: "ItemSalesTaxQueryRs - process", receive_configs: receive_configs, records: records})
        salestaxproduct_params = receive_configs.find { |c| c['salestaxproducts'] }

        if salestaxproduct_params
          payload = { salestaxproducts: products_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}
          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          salestaxproduct_params['salestaxproducts']['quickbooks_since'] = last_time_modified
          salestaxproduct_params['salestaxproducts']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = salestaxproduct_params['salestaxproducts']
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
            object_type: 'salestaxproduct',
            object_ref: build_product_id_or_ref(record),
            product_id: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def build_product_id_or_ref(object)
        return object['Name'] if object['ParentRef'].nil?
        
        if object['ParentRef'].is_a?(Array)
          arr = object['ParentRef']
        else
          arr = [object['ParentRef']]
        end
        
        arr.map do |item|
          next unless item['FullName']
          "#{item['FullName']}:"
        end.join('') + object['Name']
      end

      def products_to_flowlink
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            qbe_id: record['ListID'],
            created_at: record['TimeCreated'],
            modified_at: record['TimeModified'],
            key: ['qbe_id', 'external_guid'],
            name: record['Name'],
            fullname: record['Name'],
            barcode_value: record['BarCodeValue'],
            is_active: record['IsActive'],
            description: record['ItemDesc'],
            tax_rate: record['TaxRate'],
            external_guid: record['ExternalGUID'],
            tax_vendor_name: record.dig('TaxVendorRef', 'FullName'),
            sales_tax_return_line_name: record.dig('SalesTaxReturnLineRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            qbe_item_type: 'sales_tax'
          }.compact

          object
        end
      end
    end
  end
end
