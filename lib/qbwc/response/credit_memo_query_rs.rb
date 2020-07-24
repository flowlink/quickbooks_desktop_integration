module QBWC
  module Response
    class CreditMemoQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Credit Memos'),
                                           'creditmemos',
                                           error[:request_id])
        end
      end

      def process(config)
        return if records.empty?

        receive_configs = config[:receive] || []
        credit_params = receive_configs.find { |c| c['creditmemos'] }

        if credit_params
          payload = { creditmemos: to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == 'origin'}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling_without_timestamp

          credit_params['creditmemos']['quickbooks_since'] = last_time_modified
          credit_params['creditmemos']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = credit_params['creditmemos']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)

        nil
      end

      private

      def objects_to_update
        records.map do |record|
          {
            object_type: 'creditmemos',
            id: record['TxnID'],
            transaction_id: record['TxnID'],
            list_id: record['TxnID'],
            transaction_number: record['TxnNumber'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end


      def to_flowlink
        records.map do |record|
          if record['CreditMemoLineRet'].is_a?(Hash)
            record['CreditMemoLineRet'] = [record['CreditMemoLineRet']]
          end

          {
            id: record['TxnID'],
            list_id: record['TxnID'],
            qbe_id: record['TxnID'],
            transaction_number: record['TxnNumber'],
            ref_number: record['RefNumber'],
            external_guid: record['ExternalGUID'],
            key: ['qbe_id', 'external_guid'],
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            billing_address: {
              address1: record.dig('BillAddress', 'Addr1'),
              address2: record.dig('BillAddress', 'Addr2'),
              address3: record.dig('BillAddress', 'Addr3'),
              address4: record.dig('BillAddress', 'Addr4'),
              address5: record.dig('BillAddress', 'Addr5'),
              city: record.dig('BillAddress', 'City'),
              state: record.dig('BillAddress', 'State'),
              country: record.dig('BillAddress', 'Country'),
              zip_code: record.dig('BillAddress', 'PostalCode'),
              note: record.dig('BillAddress', 'Note')
            }.compact,
            total: record['TotalAmount'],
            subtotal: record['Subtotal'],
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
            }.compact,
            class_name: record.dig('ClassRef', 'FullName'),
            customer_name: record.dig('CustomerRef', 'FullName'),
            customer: {
              name: record.dig('CustomerRef', 'FullName'),
            },
            ar_account: record.dig('ARAccountRef', 'FullName'),
            template: record.dig('TemplateRef', 'FullName'),
            is_pending: record['IsPending'],
            fob: record['FOB'],
            ship_date: record['ShipDate'].to_s,
            ship_method: record.dig('ShipMethodRef', 'FullName'),
            item_sales_tax: record.dig('ItemSalesTaxRef', 'FullName'),
            sales_tax_total: record['SalesTaxTotal'],
            sales_tax_percentage: record['SalesTaxPercentage'],
            memo: record['Memo'],
            po_number: record['PONumber'],
            invoice: {
              po_number: record['PONumber'],
            },
            order: {
              purchase_order_number: record['PONumber'],
            },
            credit_remaining: record['CreditRemaining'],
            exchange_rate: record['ExchangeRate'],
            currency: record.dig('CurrencyRef', 'FullName'),
            customer_msg: record.dig('CustomerMsgRef', 'FullName'),
            is_to_be_printed: record['IsToBePrinted'],
            is_to_be_emailed: record['IsToBeEmailed'],
            is_tax_included: record['IsTaxIncluded'],
            customer_sales_tax_code_ref: record.dig('CustomerSalesTaxCodeRef', 'FullName'),
            line_items: line_items(record),
            linked_qbe_transactions: linked_qbe_transactions(record),
            other: record['Other'],
            relationships: [
              { key: 'name', object: 'customer'},
              { key: 'po_number', object: 'invoice' },
              { key: 'sku', object: 'product', location: 'line_items'},
              { key: 'purchase_order_number', object: 'order' }
            ]
          }.compact
        end
      end

      def line_items(record)
        return unless record["CreditMemoLineRet"]
        record['CreditMemoLineRet'] = [record['CreditMemoLineRet']] if record['CreditMemoLineRet'].is_a?(Hash)

        record["CreditMemoLineRet"].map do |item|
          {
            line_id: item["TxnLineID"],
            product_id: item.dig("ItemRef", "FullName"),
            name: item.dig("ItemRef", "FullName"),
            sku: item.dig("ItemRef", "FullName"),
            qbe_id: item.dig('ItemRef', 'ListID'),
            description: item["Desc"],
            quantity: item["Quantity"],
            line_item_quantity: item["Quantity"],
            override_uom_set_name: item.dig("OverrideUOMSetRef", "FullName"),
            unit_of_measure: item["UnitOfMeasure"],
            rate: item["Rate"],
            line_item_rate: item["Rate"],
            rate_percent: item["RatePercent"],
            amount: item["Amount"],
            line_item_amount: item["Amount"],
            class_ref: item.dig("ClassRef", "FullName"),
            warehouse: item.dig("InventorySiteRef", "FullName"),
            inventory_site_location_name: item.dig("InventorySiteLocationRef", "FullName"),
            serial_number: item["SerialNumber"],
            lot_number: item["LotNumber"],
            service_date: item['ServiceDate'].to_s,
            sales_tax_code: item.dig("SalesTaxCodeRef", "FullName"),
            other_one: item['Other1'],
            other_two: item['Other2']
          }.compact
        end
      end

      def linked_qbe_transactions(record)
        return unless record['LinkedTxn']
        record['LinkedTxn'] = [record['LinkedTxn']] if record['LinkedTxn'].is_a?(Hash)

        record['LinkedTxn'].to_a.map do |txn|
          {
            qbe_transaction_id: txn['TxnID'],
            qbe_reference_number: txn['RefNumber'],
            transaction_type: txn['TxnType'],
            transaction_date: txn['TxnDate'].to_s,
            link_type: txn['LinkType'],
            amount: txn['Amount'],
            line_item_amount: txn['Amount']
          }
        end
      end

    end
  end
end
