module QBWC
  module Response
    class SalesOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Orders'),
                                           'orders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        order_params = receive_configs.find { |c| c['orders'] }

        if order_params
          payload = { orders: orders_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling_without_timestamp

          order_params['orders']['quickbooks_since'] = last_time_modified
          order_params['orders']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = order_params['orders']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        if records.first['request_id'].start_with?('shipment')
          _, shipment_id, _ = records.first['request_id'].split('-')
          Persistence::Object.new(config, {}).update_shipments_with_qb_ids(shipment_id, objects_updated.first)
        else
          # We only need to update files when is not shipments order
          Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)
        end

        nil
      end

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'order',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence'],
            extra_data: build_extra_data(config, record)
          }.with_indifferent_access
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      def build_extra_data(config, record)
        hash_items = build_hash_items(record)
        object_source = Persistence::Session.load(config, record['request_id'])

        mapped_lines = object_source['line_items'].to_a.map do |item|
          item['txn_line_id'] = hash_items[item['product_id'].downcase]
          item['txn_id']      = record['TxnID']
          item
        end

        mapped_adjustments = object_source['adjustments'].to_a.map do |item|
          item['txn_line_id'] = hash_items[QBWC::Request::Adjustments.adjustment_product_from_qb(item['name'].downcase, config).to_s.downcase]
          item['txn_id']      = record['TxnID']
          item
        end

        {
          'line_items' => mapped_lines,
          'adjustments' => mapped_adjustments
        }
      end

      def build_hash_items(record)
        hash = {}

        # Sometimes is an array, sometimes is not :-/
        record['SalesOrderLineRet'] = [record['SalesOrderLineRet']] unless record['SalesOrderLineRet'].is_a? Array

        record['SalesOrderLineRet'].to_a.each do |item|
          next unless item && item['ItemRef']
          
          hash[item['ItemRef']['FullName'].downcase] = item['TxnLineID']
        end
        hash
      end

      def orders_to_flowlink
        records.map do |record|
          {
            id: record['RefNumber'],
            transaction_id: record['TxnID'],
            created_at: record["TimeCreated"].to_s,
            modified_at: record["TimeModified"].to_s,
            transaction_number: record["TxnNumber"],
            transaction_date: record["TxnDate"],
            po_number: record["PONumber"],
            due_date: record["DueDate"].to_s,
            customer: {
              name: record.dig("CustomerRef", "FullName"),
              external_id: record.dig("CustomerRef", "ListID")
            },
            billing_address: {
              address1: record.dig("BillAddress", "Addr1"),
              address2: record.dig("BillAddress", "Addr2"),
              address3: record.dig("BillAddress", "Addr3"),
              address4: record.dig("BillAddress", "Addr4"),
              address5: record.dig("BillAddress", "Addr5"),
              city: record.dig("BillAddress", "City"),
              state: record.dig("BillAddress", "State"),
              country: record.dig("BillAddress", "Country"),
              zip_code: record.dig("BillAddress", "PostalCode"),
              note: record.dig("BillAddress", "Note")
            }.compact,
            shipping_address: {
              address1: record.dig("ShipAddress", "Addr1"),
              address2: record.dig("ShipAddress", "Addr2"),
              address3: record.dig("ShipAddress", "Addr3"),
              address4: record.dig("ShipAddress", "Addr4"),
              address5: record.dig("ShipAddress", "Addr5"),
              city: record.dig("ShipAddress", "City"),
              state: record.dig("ShipAddress", "State"),
              country: record.dig("ShipAddress", "Country"),
              zip_code: record.dig("ShipAddress", "PostalCode"),
              note: record.dig("ShipAddress", "Note")
            }.compact,
            sales_rep: {
              name: record.dig("SalesRepRef", "FullName")
            },
            customer_message_name: record.dig("CustomerMsgRef", "FullName"),
            template_name: record.dig("TemplateRef", "FullName"),
            terms: record.dig("TermsRef", "FullName"),
            currency_name: record.dig("CurrencyRef", "FullName"),
            tax_ref: record.dig("ItemSalesTaxRef", "FullName"),
            shipping_method: record.dig("ShipMethodRef", "FullName"),
            customer_tax_code: record.dig("CustomerSalesTaxCodeRef", "FullName"),
            class_ref: record.dig("ClassRef", "FullName"),
            shipping_date: record["ShipDate"].to_s,
            sub_total: record["Subtotal"],
            sales_tax_percentage: record["SalesTaxPercentage"],
            sales_tax_total: record["SalesTaxTotal"],
            total: record["TotalAmount"],
            is_manually_closed: record["IsManuallyClosed"],
            is_fully_invoiced: record["IsFullyInvoiced"],
            line_items: line_items(record),
            fob: record['FOB'],
            exchange_rate: record['ExchangeRate'],
            total_amount_in_home_currency: record['TotalAmountInHomeCurrency'],
            memo: record['Memo'],
            is_to_be_printed: record['IsToBePrinted'],
            is_to_be_emailed: record['IsToBeEmailed'],
            is_tax_included: record['IsTaxIncluded'],
            other: record['Other'],
            external_guid: record['ExternalGUID'],
            linked_qbe_transactions: linked_qbe_transactions(record)
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
            line_item_amount: item['Amount']
          }
        end
      end

      def grouped_line_items(record)
        return unless record['SalesOrderLineGroupRet']
        record['SalesOrderLineGroupRet'] = [record['SalesOrderLineGroupRet']] if record['SalesOrderLineGroupRet'].is_a?(Hash)
        
        record['SalesOrderLineGroupRet'].map do |group_item|
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

      def line_items(record)
        return unless record["SalesOrderLineRet"]
        record['SalesOrderLineRet'] = [record['SalesOrderLineRet']] if record['SalesOrderLineRet'].is_a?(Hash)
        
        record["SalesOrderLineRet"].map do |item|
          {
            product_id: item.dig("ItemRef", "FullName"),
            name: item.dig("ItemRef", "FullName"),
            sku: item.dig("ItemRef", "FullName"),
            qbe_id: item.dig('ItemRef', 'ListID'),
            class_ref: item.dig("ClassRef", "FullName"),
            warehouse: item.dig("InventorySiteRef", "FullName"),
            sales_tax_code: item.dig("SalesTaxCodeRef", "FullName"),
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
            line_item_amount: item['Amount'],
            invoiced: item["Invoiced"],
            is_manually_closed: item["IsManuallyClosed"],
            service_date: item['ServiceDate'].to_s,
            other_one: item['Other1'],
            other_two: item['Other2']
          }
        end
      end
    end
  end
end
