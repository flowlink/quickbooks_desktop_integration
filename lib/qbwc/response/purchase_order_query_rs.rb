module QBWC
  module Response
    class PurchaseOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying purchase orders'),
                                           'purchaseorders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        # puts "Processing purchase orders: #{records}"
        receive_configs = config[:receive] || []
        purchaseorder_params = receive_configs.find { |c| c['purchaseorders'] }

        if purchaseorder_params
          payload = { purchaseorders: purchaseorders_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == 'origin'}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          purchaseorder_params['purchaseorders']['quickbooks_since'] = last_time_modified
          purchaseorder_params['purchaseorders']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = purchaseorder_params['purchaseorders']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        nil
      end

      private

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'purchaseorder',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }.with_indifferent_access
        end
      end

      def purchaseorders_to_flowlink
        records.map do |record|
          # puts "Purchase Order from QBE: #{record}"
          if record['PurchaseOrderLineRet'].is_a?(Hash)
            record['PurchaseOrderLineRet'] = [record['PurchaseOrderLineRet']]
          end
          {
            id: record['RefNumber'],
            transaction_id: record['TxnId'],
            is_fully_received: record['IsFullyReceived'],
            qbe_transaction_id: record['TxnID'],
            key: 'qbe_transaction_id',
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            transaction_number: record['TxnNumber'],
            due_date: record['DueDate'].to_s,
            is_manually_closed: record['IsManuallyClosed'],
            fob: record['FOB'],
            memo: record['Memo'],
            exchange_rate: record['ExchangeRate'],
            is_to_be_printed: record['IsToBePrinted'],
            is_to_be_emailed: record['IsToBeEmailed'],
            is_tax_included: record['IsTaxIncluded'],
            other_one: record['Other'],
            other_two: record['Other2'],
            external_guid: record['ExternalGUID'],
            expected_date: record['ExpectedDate'].to_s,
            total_amount_in_home_currency: record['TotalAmountInHomeCurrency'],
            vendor_message: record['VendorMsg'],
            transaction_date: record['Txndate'],
            total: record['TotalAmount'],
            vendor_address: {
              address1: record.dig('VendorAddress', 'Addr1'),
              address2: record.dig('VendorAddress', 'Addr2'),
              address3: record.dig('VendorAddress', 'Addr3'),
              address4: record.dig('VendorAddress', 'Addr4'),
              address5: record.dig('VendorAddress', 'Addr5'),
              city: record.dig('VendorAddress', 'City'),
              state: record.dig('VendorAddress', 'State'),
              country: record.dig('VendorAddress', 'Country'),
              zip_code: record.dig('VendorAddress', 'PostalCode'),
              note: record.dig('VendorAddress', 'Note')
            },
            shipping_address: {
              address1: record.dig('ShipAddress', 'Addr1'),
              address2: record.dig('ShipAddress', 'Addr2'),
              address3: record.dig('ShipAddress', 'Addr3'),
              address4: record.dig('ShipAddress', 'Addr4'),
              address5: record.dig('ShipAddress', 'Addr5'),
              city: record.dig('ShipAddress', 'City'),
              state: record.dig('ShipAddress', 'State'),
              country: record.dig('ShipAddress', 'Country'),
              zip_code: record.dig('ShipAddress', 'PostalCode'),
              note: record.dig('ShipAddress', 'Note')
            },
            vendor: {
              name: record.dig('VendorRef','FullName'),
              external_id: record.dig('VendorRef','ListID')
            },
            class_name: record.dig('ClassRef','FullName'),
            inventory_site_name: record.dig('InventorySiteRef','FullName'),
            ship_to_entity_name: record.dig('ShipToEntityRef','FullName'),
            template_name: record.dig('TemplateRef','FullName'),
            terms: record.dig('TermsRef','FullName'),
            shipping_method: record.dig('ShipMethodRef','FullName'),
            currency_name: record.dig('CurrencyRef','FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef','FullName'),
            line_items: record['PurchaseOrderLineRet'].map do |item|
              puts "purchase order item: #{item}"
              {
                product_id: item.dig('ItemRef', 'FullName'),
                name: item.dig('ItemRef', 'FullName'),
                sku: item.dig('ItemRef', 'FullName'),
                qbe_id: item.dig('ItemRef', 'ListID'),
                class_ref: item.dig('ClassRef', 'FullName'),
                sales_tax_code: item.dig('SalesTaxCodeRef', 'FullName'),
                override_uom_set_name: item.dig('OverrideUOMSetRef', 'FullName'),
                inventory_site_location_name: item.dig('InventorySiteLocationRef', 'FullName'),
                customer: {
                  name: record.dig("CustomerRef", "FullName"),
                  external_id: record.dig("CustomerRef", "ListID")
                },
                description: item['Desc'],
                quantity: item['Quantity'],
                value: item['Amount'],
                transaction_line_id: record['TxnLineID'],
                line_item_manufacturer_part_number: record['ManufacturerPartNumber'],
                line_item_unit_of_measure: record['UnitOfMeasure'],
                line_item_rate: record['Rate'],
                line_item_service_date: record['ServiceDate'],
                line_item_received_quantity: record['ReceivedQuantity'],
                line_item_unbilled_quantity: record['UnbilledQuantity'],
                line_item_is_billed: record['IsBilled'],
                line_item_is_manually_closed: record['IsManuallyClosed'],
                line_item_other_one: record['Other1'],
                line_item_other_two: record['Other2']
              }
            end
          }.compact
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end
    end
  end
end
