module QBWC
  module Response
    class SalesReceiptQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying salesreceipts'),
                                           'salesreceipts',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config  = { origin: 'flowlink', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      def objects_to_update
        records.map do |record|
          {
            object_type: 'salesreceipt',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def sales_receipts_to_flowlink
        records.map do |record|

          if record['SalesReceiptLineRet'].is_a?(Hash)
            record['SalesReceiptLineRet'] = [record['SalesReceiptLineRet']]
          end
          
          {
            id: record['RefNumber'],
            is_pending: record['IsPending'],
            transaction_id: record['TxnID'],
            qbe_transaction_id: record['TxnID'],
            key: 'qbe_transaction_id',
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            transaction_number: record['TxnNumber'],
            transaction_date: record['TxnDate'],
            due_date: record['DueDate'].to_s,
            shipping_date: record['ShipDate'].to_s,
            sub_total: record['Subtotal'],
            sales_tax_total: record['SalesTaxTotal'],
            total: record['TotalAmount'],
            is_manually_closed: record['IsManuallyClosed'],
            fob: record['fob'],
            memo: record['Memo'],
            check_number: record['CheckNumber'],
            total_amount_in_home_currency: record['TotalAmountInHomeCurrency'],
            exchange_rate: record['ExchangeRate'],
            is_to_be_printed: record['IsToBePrinted'],
            is_to_be_emailed: record['IsToBeEmailed'],
            is_tax_included: record['IsTaxIncluded'],
            other: record['Other'],
            external_guid: record['ExternalGUID'],
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
            customer: {
              name: record.dig('CustomerRef', 'FullName'),
              external_id: record.dig('CustomerRef', 'ListID'),
              qbe_id: record.dig('CustomerRef', 'ListID')
            },
            sales_rep: {
              name: record.dig('SalesRepRef', 'FullName')
            },
            class_ref: record.dig('ClassRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            customer_tax_code: record.dig('CustomerSalesTaxCodeRef', 'FullName'),
            shipping_method: record.dig('ShipMethodRef', 'FullName'),
            tax_ref: record.dig('ItemSalesTaxRef', 'FullName'),
            template_name: record.dig('TemplateRef', 'FullName'),
            currency_name: record.dig('CurrencyRef', 'FullName'),
            customer_msg_name: record.dig('CustomerMsgRef', 'FullName'),
            payment_method: record.dig('PaymentMethodRef', 'FullName'),
            deposit_to_account_name: record.dig('DepositToAccountRef', 'FullName'),
            line_items: line_items(record),
            grouped_line_items: grouped_line_items(record),
            relationships: [
              { object: 'customer', key: 'qbe_id' },
              { object: 'product', key: 'qbe_id', location: 'line_items' }
            ]
          }.compact
        end
      end

      def line_items(record)
        return unless record["SalesReceiptLineRet"]
        record['SalesReceiptLineRet'] = [record['SalesReceiptLineRet']] if record['SalesReceiptLineRet'].is_a?(Hash)
        
        record["SalesReceiptLineRet"].map do |item|
          {
            product_id: item.dig("ItemRef", "FullName"),
            name: item.dig("ItemRef", "FullName"),
            sku: item.dig("ItemRef", "FullName"),
            qbe_id: item.dig('ItemRef', 'ListID'),
            warehouse: item.dig("InventorySiteRef", "FullName"),
            sales_tax_code: item.dig("SalesTaxCodeRef", "FullName"),
            class_ref: item.dig("ClassRef", "FullName"),
            override_uom_set_name: item.dig("OverrideUOMSetRef", "FullName"),
            inventory_site_location_name: item.dig("InventorySiteLocationRef", "FullName"),
            line_id: item["TxnLineID"],
            description: item["Desc"],
            quantity: item["Quantity"],
            line_item_quantity: item["Quantity"],
            unit_of_measure: item["UnitOfMeasure"],
            rate: item["Rate"],
            line_item_rate: item["Rate"],
            rate_percent: item["RatePercent"],
            serial_number: item["SerialNumber"],
            lot_number: item["LotNumber"],
            amount: item["Amount"],
            line_item_amount: item["Amount"],
            invoiced: item["Invoiced"],
            is_manually_closed: item["IsManuallyClosed"],
            service_date: item['ServiceDate'].to_s,
            other_one: item['Other1'],
            other_two: item['Other2']
          }
      end
    end

      def grouped_line_items(record)
        return unless record['SalesReceiptLineGroupRet']
        record['SalesReceiptLineGroupRet'] = [record['SalesReceiptLineGroupRet']] if record['SalesReceiptLineGroupRet'].is_a?(Hash)
        
        record['SalesReceiptLineGroupRet'].map do |group_item|
          {
            line_id: group_item['TxnLineID'],
            description: group_item['Desc'],
            quantity: group_item['Quantity'],
            line_item_quantity: item["Quantity"],
            unit_of_measure: group_item['UnitOfMeasure'],
            is_print_items_in_group: group_item['IsPrintItemsInGroup'],
            total_amount: group_item['TotalAmount'],
            override_uom_set_name: group_item.dig("OverrideUOMSetRef", "FullName"),
            item_group_name: group_item.dig("ItemGroupRef", "FullName"),
            line_items: line_items(group_item)
            }.compact
        end
      end
    end
  end
end
