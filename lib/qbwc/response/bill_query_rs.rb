module QBWC
  module Response
    class BillQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying bills'),
                                           'bills',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        bill_params = receive_configs.find { |c| c['bills'] }

        if bill_params
          payload = { bills: bills_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == 'origin'}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          bill_params['bills']['quickbooks_since'] = last_time_modified
          bill_params['bills']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = bill_params['bills']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)

        nil
      end

      def last_time_modified
        date = records.sort_by { |r| r['TxnDate'] }.last['TxnDate'].to_s
        puts Date.parse(date).to_time.in_time_zone('Pacific Time (US & Canada)').iso8601
        Date.parse(date).to_time.in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'bill',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence'],
            extra_data: build_extra_data(config, record)
          }.with_indifferent_access
        end
      end

      def build_extra_data(config, record)
        hash_items = build_hash_items(record)
        object_source = Persistence::Session.load(config, record['request_id'])

        mapped_expenses = object_source['expense_lines'].to_a.map do |item, i|
          item['txn_line_id'] = i
          item['txn_id'] = record['TxnID']
          item
        end

        mapped_lines = object_source['line_items'].to_a.map do |item|
          item['txn_line_id'] = hash_items[item['product_id'].downcase]
          item['txn_id'] = record['TxnID']
          item
        end

        mapped_adjustments = object_source['adjustments'].to_a.map do |item|
          item['txn_line_id'] = hash_items[QBWC::Request::Adjustments.adjustment_product_from_qb(item['name'].downcase, config).to_s.downcase]
          item['txn_id'] = record['TxnID']
          item
        end

        {
          'expense_lines' => mapped_expenses,
          'line_items' => mapped_lines,
          'adjustments' => mapped_adjustments
        }
      end

      def build_hash_items(record)
        hash = {}

        # Sometimes is an array, sometimes is not :-/
        record['ItemLineRet'] = [record['ItemLineRet']] unless record['ItemLineRet'].is_a? Array

        record['ItemLineRet'].to_a.each do |item|
          next unless item && item['ItemRef']

          hash[item['ItemRef']['FullName'].downcase] = item['TxnLineID']
        end
        hash
      end

      def bills_to_flowlink
        records.map do |record|
          {
            id: record['RefNumber'],
            transaction_id: record['TxnID'],
            qbe_transaction_id: record['TxnID'],
            key: 'qbe_transaction_id',
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            transaction_number: record['TxnNumber'],
            transaction_date: record['TxnDate'],
            due_date: record['DueDate'].to_s,
            exchange_rate: record['ExchangeRate'],
            memo: record['Memo'],
            is_tax_included: record['IsTaxIncluded'],
            is_paid: record['IsPaid'],
            external_guid: record['ExternalGUID'],
            open_amount: record['OpenAmount'],
            amount_due: record['AmountDue'],
            amount_due_in_home_currency: record['AmountDueInHomeCurrency'],
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
            }.compact,
            vendor: {
              name: record.dig('VendorRef', 'FullName'),
              external_id: record.dig('VendorRef', 'ListID'),
              qbe_id: record.dig('VendorRef', 'ListID')
            },
            currency_name: record.dig('CurrencyRef', 'FullName'),
            terms: record.dig('TermsRef', 'FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef', 'FullName'),
            apa_account: record.dig('APAccountRef', 'FullName'),
            relationships: [
              { object: 'vendor', key: 'qbe_id' },
              { object: 'product', key: 'qbe_id', location: 'line_items' }
            ],
            line_items: line_items(record),
            grouped_line_items: grouped_line_items(record),
            expense_line_items: expense_line_items(record),
            linked_qbe_transactions: linked_qbe_transactions(record),
            qbe_custom_fields: extra_data(record)
          }.compact
        end
      end

      def linked_qbe_transactions(record)
        return unless record['LinkedTxn']
        record['LinkedTxn'] = [record['LinkedTxn']] if record['LinkedTxn'].is_a?(Hash)

        record['LinkedTxn'].map do |txn|
          {
            qbe_transaction_id: txn['TxnID'],
            qbe_reference_number: txn['RefNumber'],
            transaction_type: txn['TxnType'],
            transaction_date: txn['TxnDate'].to_s,
            link_type: txn['LinkType'],
            amount: txn['Amount'],
          }
        end
      end

      def line_items(record)
        return unless record['ItemLineRet']
        record['ItemLineRet'] = [record['ItemLineRet']] if record['ItemLineRet'].is_a?(Hash)
        
        record['ItemLineRet'].map do |item|
          {
            product_id: item.dig('ItemRef', 'FullName'),
            qbe_id: item.dig('ItemRef', 'ListID'),
            name: item.dig('ItemRef', 'FullName'),
            sku: item.dig('ItemRef', 'FullName'),
            class_ref: item.dig('ClassRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            warehouse: item.dig('InventorySiteRef', 'FullName'),
            sales_tax_code: item.dig('SalesTaxCodeRef', 'FullName'),
            override_uom_set_name: item.dig("OverrideUOMSetRef", "FullName"),
            inventory_site_location_name: item.dig("InventorySiteLocationRef", "FullName"),
            sales_rep_name: record.dig('SalesRepRef', 'FullName'),
            sales_rep: {
              name: record.dig('SalesRepRef', 'FullName')
            },
            line_id: item['TxnLineID'],
            description: item['Desc'],
            quantity: item['Quantity'],
            unit_of_measure: item['UnitOfMeasure'],
            serial_number: item["SerialNumber"],
            lot_number: item["LotNumber"],
            amount: item['Amount'],
            cost: item['Cost'],
            billable_status: item['BillableStatus'],
            qbe_custom_fields: extra_data(item)
          }.compact
        end
      end

      def expense_line_items(record)
        return unless record['ExpenseLineRet']
        record['ExpenseLineRet'] = [record['ExpenseLineRet']] if record['ExpenseLineRet'].is_a?(Hash)
        
        record['ExpenseLineRet'].map do |item|
          {
            class_ref: item.dig('ClassRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            account_name: item.dig('AccountRef', 'FullName'),
            sales_tax_code: item.dig('SalesTaxCodeRef', 'FullName'),
            customer_name: item.dig("CustomerRef", "FullName"),
            sales_rep_name: record.dig('SalesRepRef', 'FullName'),
            sales_rep: {
              name: record.dig('SalesRepRef', 'FullName')
            },
            line_id: item['TxnLineID'],
            amount: item['Amount'],
            description: item['Memo'],
            billable_status: item['BillableStatus'],
            qbe_custom_fields: extra_data(item)
          }.compact
        end
      end

      def grouped_line_items(record)
        return unless record['InvoiceLineGroupRet']
        record['InvoiceLineGroupRet'] = [record['InvoiceLineGroupRet']] if record['InvoiceLineGroupRet'].is_a?(Hash)
        
        record['InvoiceLineGroupRet'].map do |group_item|
          {
            line_id: group_item['TxnLineID'],
            description: group_item['Desc'],
            quantity: group_item['Quantity'],
            unit_of_measure: group_item['UnitOfMeasure'],
            is_print_items_in_group: group_item['IsPrintItemsInGroup'],
            total_amount: group_item['TotalAmount'],
            override_uom_set_name: group_item.dig("OverrideUOMSetRef", "FullName"),
            item_group_name: group_item.dig("ItemGroupRef", "FullName"),
            line_items: line_items(group_item)
            }.compact
        end
      end

      def extra_data(obj)
        return unless obj['DataExtRet']
        obj['DataExtRet'] = [obj['DataExtRet']] if obj['DataExtRet'].is_a?(Hash)
        
        obj['DataExtRet'].map do |item|
          {
            owner_id: item['OwnerID'],
            name: item['DataExtName'],
            type: item['DataExtType'],
            value: item['DataExtValue']
          }
        end
      end

    end
  end
end
