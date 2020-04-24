module QBWC
  module Response
    class ItemDiscountQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying discount products'),
                                           'products',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        discountproduct_params = receive_configs.find { |c| c['discountproducts'] }

        if discountproduct_params
          payload = { discountproducts: discountproducts_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}
          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          discountproduct_params['discountproducts']['quickbooks_since'] = last_time_modified
          discountproduct_params['discountproducts']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = discountproduct_params['discountproducts']
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
            object_type: 'discountproduct',
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

      def discountproducts_to_flowlink
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            qbe_id: record['ListID'],
            key: 'qbe_id',
            name: record['Name'],
            external_guid: record['ExternalGUID'],
            created_at: record['TimeCreated'],
            modified_at: record['TimeModified'],
            fullname: record['FullName'],
            is_active: record['IsActive'],
            barcode_value: record['BarCodeValue'],
            sublevel: record['Sublevel'],
            description: record['ItemDesc'],
            discount_rate: record['DiscountRate'],
            discount_rate_percent: record['DiscountRatePercent'],
            class_name: record.dig('ClassRef', 'FullName'),
            parent_name: record.dig('ParentRef', 'FullName'),
            account_name: record.dig('AccountRef', 'FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef', 'FullName'),
            qbe_item_type: 'discount'
          }.compact

          object
        end
      end
    end
  end
end
