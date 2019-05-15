module QBWC
  module Response
    class InvoiceQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying invoices'),
                                           'invoices',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        invoice_params = receive_configs.find { |c| c['invoices'] }

        if invoice_params
          payload = { invoices: invoices_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          invoice_params['invoices']['quickbooks_since'] = last_time_modified
          invoice_params['invoices']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = invoice_params['invoices']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        if records.first['request_id'].start_with?('shipment')
          _, shipment_id, _ = records.first['request_id'].split('-')
          Persistence::Object.new(config, {}).update_shipments_with_qb_ids(shipment_id, objects_updated.first)
        else
          # We only need to update files when is not shipments invoice
          Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)
        end

        nil
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'invoice',
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
        record['InvoiceLineRet'] = [record['InvoiceLineRet']] unless record['InvoiceLineRet'].is_a? Array

        record['InvoiceLineRet'].to_a.each do |item|
          next unless item['ItemRef']

          hash[item['ItemRef']['FullName'].downcase] = item['TxnLineID']
        end
        hash
      end

      def invoices_to_flowlink
        records.map do |record|
          puts "invoice from qbe: #{record}"
          if record['InvoiceLineRet'].is_a?(Hash)
            record['InvoiceLineRet'] = [record['InvoiceLineRet']]
          end
          

          {
            id: record['RefNumber'],
            is_pending: record['IsPending'],
            is_finance_charge: record['IsFinanceCharge'],
            is_paid: record['IsPaid'],
            transaction_id: record['TxnId'],
            created_at: record["TimeCreated"].to_s,
            modified_at: record["TimeModified"].to_s,
            transaction_number: record["TxnNumber"],
            customer: {
              name: record.dig("CustomerRef", "FullName"),
              external_id: record.dig("CustomerRef", "ListID")
            },
            class_ref: record.dig("ClassRef", "FullName"),
            transaction_date: record["TxnDate"],
            ara_account: record.dig("ARAccountRef", "FullName"),

            billing_address: {
              address1: record.dig("BillAddress", "Addr1"),
              address2: record.dig("BillAddress", "Addr2"),
              city: record.dig("BillAddress", "City"),
              state: record.dig("BillAddress", "State"),
              country: record.dig("BillAddress", "Country"),
              zip_code: record.dig("BillAddress", "PostalCode")
            },
            shipping_address: {
              address1: record.dig("ShipAddress", "Addr1"),
              address2: record.dig("ShipAddress", "Addr2"),
              city: record.dig("ShipAddress", "City"),
              state: record.dig("ShipAddress", "State"),
              country: record.dig("ShipAddress", "Country"),
              zip_code: record.dig("ShipAddress", "PostalCode")
            },
            po_number: record["PONumber"],
            due_date: record["DueDate"].to_s,
            sales_rep: {
              name: record.dig("SalesRepRef", "FullName")
            },
            shipping_date: record["ShipDate"].to_s,
            sub_total: record["Subtotal"],
            sales_tax_percentage: record["SalesTaxPercentage"],
            sales_tax_total: record["SalesTaxTotal"],
            total: record["TotalAmount"],
            is_manually_closed: record["IsManuallyClosed"],
            is_fully_invoiced: record["IsFullyInvoiced"],
            customer_tax_code: record.dig("CustomerSalesTaxCodeRef", "FullName"),
            line_items: record["InvoiceLineRet"].map do |item|
              {
                product_id: item.dig("ItemRef", "FullName"),
                line_id: item["TxnLineID"],
                description: item["Desc"],
                quantity: item["Quantity"],
                unit_of_measure: item["UnitOfMeasure"],
                rate: item["Rate"],
                class_ref: item.dig("ClassRef", "FullName"),
                amount: item["Amount"],
                warehouse: item.dig("InventorySiteRef", "FullName"),
                sales_tax_code: item.dig("SalesTaxCodeRef", "FullName"),
                invoiced: item["Invoiced"],
                is_manually_closed: item["IsManuallyClosed"]
              }
            end,
            terms: record.dig("TermsRef", "FullName"),
            fob: record["fob"],
            shipping_method: record.dig("ShipMethodRef", "FullName"),
            tax_ref: record.dig("ItemSalesTaxRef", "FullName"),
            applied_amount: record["AppliedAmount"],
            balance_remaining: record["BalanceRemaining"],
            memo: record["Memo"]
          }
        end
      end




      def to_flowlink
        # TODO finish the map
        records.map do |record|
          object = {
            id: record['RefNumber']
          }

          object
        end
      end
    end
  end
end
