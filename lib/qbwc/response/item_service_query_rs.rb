module QBWC
  module Response
    class ItemServiceQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying service products'),
                                           'serviceproducts',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        puts({connection_id: config[:connection_id], method: "ItemServiceQueryRs - process", receive_configs: receive_configs})
        serviceproduct_params = receive_configs.find { |c| c['serviceproducts'] }

        if serviceproduct_params
          payload = { serviceproducts: products_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}
          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          serviceproduct_params['serviceproducts']['quickbooks_since'] = last_time_modified
          serviceproduct_params['serviceproducts']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = serviceproduct_params['serviceproducts']
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
            object_type: 'serviceproduct',
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
            key: 'qbe_id',
            name: record['Name'],
            fullname: record['FullName'],
            created_at: record['TimeCreated'],
            modified_at: record['TimeModified'],
            is_active: record['IsActive'],
            barcode_value: record['BarCodeValue'],
            sublevel: record['Sublevel'],
            is_tax_included: record['IsTaxIncluded'],
            external_guid: record['ExternalGUID'],
            vendor: {
              name: record.dig('PrefVendorRef', 'FullName'),
              external_id: record.dig('PrefVendorRef', 'ListID'),
              qbe_id: record.dig('PrefVendorRef', 'ListID')
            },
            unit_measure: record.dig('UnitOfMeasureSetRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            parent_name: record.dig('ParentRef', 'FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef', 'FullName'),
            relationships: [
              { object: "vendor", key: "qbe_id" }
            ],
            qbe_item_type: 'service'
          }.compact

          if record['SalesOrPurchase']
            object.merge!({
              sales_or_purchase: true,
              price: record['SalesOrPurchase']['Price'],
              price_percent: record['SalesOrPurchase']['PricePercent'],
              description: record['SalesOrPurchase']['Desc'],
              account_name: record['SalesOrPurchase'].dig('AccountRef', 'FullName')
            }.compact)
          end

          if record['SalesAndPurchase']
            object.merge!({
              sales_and_purchase: true,
              sales_description: record['SalesAndPurchase']['SalesDesc'],
              sales_price: record['SalesAndPurchase']['SalesPrice'],
              price: record['SalesAndPurchase']['SalesPrice'],
              purchase_description: record['SalesAndPurchase']['PurchaseDesc'],
              purchase_cost: record['SalesAndPurchase']['PurchaseCost'],
              cost: record['SalesAndPurchase']['PurchaseCost'],
              purchase_tax_code_name: record['SalesAndPurchase'].dig('PurchaseTaxCodeRef', 'FullName'),
              income_account_name: record['SalesAndPurchase'].dig('IncomeAccountRef', 'FullName'),
              expense_account_name: record['SalesAndPurchase'].dig('ExpenseAccountRef', 'FullName'),
              sales_and_purchase_vendor: {
                name: record['SalesAndPurchase'].dig('PrefVendorRef', 'FullName'),
                external_id: record['SalesAndPurchase'].dig('PrefVendorRef', 'ListID'),
                qbe_id: record['SalesAndPurchase'].dig('PrefVendorRef', 'ListID')
              },
              relationships: [
                { object: "vendor", key: "qbe_id" },
                { object: "sales_and_purchase_vendor", key: "qbe_id" }
              ],
            }.compact)
          end

          object
        end
      end
    end
  end
end
        