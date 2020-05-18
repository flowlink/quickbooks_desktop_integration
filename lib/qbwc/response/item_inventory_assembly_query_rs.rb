module QBWC
  module Response
    class ItemInventoryAssemblyQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying assembled products'),
                                           'inventoryassemblyproducts',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }
        inventoryassemblyproduct_params = receive_configs.find { |c| c['inventoryassemblyproducts'] }

        if inventory_params
          payload = { inventories: inventories_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling
        end

        if inventoryassemblyproduct_params
          payload = { inventoryassemblyproducts: products_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}
          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling_without_timestamp

          inventoryassemblyproduct_params['products']['quickbooks_since'] = last_time_modified
          inventoryassemblyproduct_params['products']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = inventoryassemblyproduct_params['products']
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

      def inventories_to_flowlink
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            quantity: record['QuantityOnHand'],
            grabbed_at: Time.now.to_s,
            fullname: record['FullName']
          }
        end
      end

      def products_to_flowlink
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            name: record['Name'],
            product_id: record['Name'],
            fullname: record['FullName'],
            quantity: record['QuantityOnHand'],
            is_active: record['IsActive'],
            sales_price: record['SalesPrice'],
            purchase_description: record['PurchaseDesc'],
            purchase_cost: record['PurchaseCost'],
            vendor: {
              name: record.dig('PrefVendorRef', 'FullName'),
              external_id: record.dig('PrefVendorRef', 'ListID')
            },
            unit_measure: record.dig('UnitOfMeasureSetRef', 'FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef', 'FullName'),
            income_account_name: record.dig('IncomeAccountRef', 'FullName'),
            purchase_tax_code_name: record.dig('PurchaseTaxCodeRef', 'FullName'),
            cogs_account_name: record.dig('COGSAccountRef', 'FullName'),
            asset_account_name: record.dig('AssetAccountRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            parent_name: record.dig('ParentRef', 'FullName'),
            average_cost: record['AverageCost'],
            quantity_on_order: record['QuantityOnOrder'],
            quantity_on_sales_order: record['QuantityOnSalesOrder'],
            created_at: record['TimeCreated'],
            modified_at: record['TimeModified'],
            list_id: record['ListID'],
            qbe_id: record['ListID'],
            key: 'qbe_id',
            barcode_value: record['BarCodeValue'],
            sublevel: record['Sublevel'],
            manufacturer_part_number: record['ManufacturerPartNumber'],
            is_tax_included: record['IsTaxIncluded'],
            sales_description: record['SalesDesc'],
            build_point: record['BuildPoint'],
            max: record['Max'],
            external_guid: record['ExternalGUID'],
            assembly_line_items: assembly_line_items(record),
            qbe_item_type: 'inventory_assembly'
          }.compact

          object
        end
      end

      def assembly_line_items(record)
        return unless record['ItemInventoryAssemblyLine']
        record['ItemInventoryAssemblyLine'] = [record['ItemInventoryAssemblyLine']] if record['ItemInventoryAssemblyLine'].is_a?(Hash)

        record['ItemInventoryAssemblyLine'].compact.map do |line|
          {
            quantity: line['Quantity'],
            item_inventory_name: line.dig('ItemInventoryRef', 'FullName')
          }
        end
      end

    end
  end
end
