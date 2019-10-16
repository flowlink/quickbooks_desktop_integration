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
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == 'origin'}

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
        puts 'SETTING A NEW SINCE DATE FOR INVOICES'
        date = records.sort_by { |r| r['TxnDate'] }.last['TxnDate'].to_s
        puts Date.parse(date).to_time.in_time_zone('Pacific Time (US & Canada)').iso8601
        Date.parse(date).to_time.in_time_zone('Pacific Time (US & Canada)').iso8601
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
          next unless item && item['ItemRef']

          hash[item['ItemRef']['FullName'].downcase] = item['TxnLineID']
        end
        hash
      end

      def invoices_to_flowlink
        records.map do |record|
          # puts "invoice from qbe: #{record}"
          if record['InvoiceLineRet'].is_a?(Hash)
            record['InvoiceLineRet'] = [record['InvoiceLineRet']]
          end

          {
            id: record['RefNumber'],
            is_pending: record['IsPending'],
            is_finance_charge: record['IsFinanceCharge'],
            is_paid: record['IsPaid'],
            transaction_id: record['TxnID'],
            qbe_transaction_id: record['TxnID'],
            key: 'qbe_transaction_id',
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            transaction_number: record['TxnNumber'],
            transaction_date: record['TxnDate'],
            customer: {
              name: record.dig('CustomerRef', 'FullName'),
              external_id: record.dig('CustomerRef', 'ListID'),
              qbe_id: record.dig('CustomerRef', 'ListID')
            },
            class_ref: record.dig('ClassRef', 'FullName'),
            class_name: record.dig('ClassRef', 'FullName'),
            ara_account: record.dig('ARAccountRef', 'FullName'),
            customer_tax_code: record.dig('CustomerSalesTaxCodeRef', 'FullName'),
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
            po_number: record['PONumber'],
            due_date: record['DueDate'].to_s,
            sales_rep: {
              name: record.dig('SalesRepRef', 'FullName')
            },
            shipping_date: record['ShipDate'].to_s,
            sub_total: record['Subtotal'],
            sales_tax_percentage: record['SalesTaxPercentage'],
            sales_tax_total: record['SalesTaxTotal'],
            total: record['TotalAmount'],
            is_manually_closed: record['IsManuallyClosed'],
            is_fully_invoiced: record['IsFullyInvoiced'],
            line_items: record['InvoiceLineRet'] && record['InvoiceLineRet'].map do |item|
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
                line_id: item['TxnLineID'],
                description: item['Desc'],
                quantity: item['Quantity'],
                unit_of_measure: item['UnitOfMeasure'],
                rate: item['Rate'] || item['RatePercent'],
                serial_or_lot_num: item["SerialNumber"] || item["LotNumber"],
                amount: item['Amount'],
                invoiced: item['Invoiced'],
                is_manually_closed: item['IsManuallyClosed'],
                service_date: item['ServiceDate'].to_s,
                other_one: item['Other1'],
                other_two: item['Other2']
              }
            end,
            terms: record.dig('TermsRef', 'FullName'),
            shipping_method: record.dig('ShipMethodRef', 'FullName'),
            tax_ref: record.dig('ItemSalesTaxRef', 'FullName'),
            template_name: record.dig('TemplateRef', 'FullName'),
            currency_name: record.dig('CurrencyRef', 'FullName'),
            customer_msg_name: record.dig('CustomerMsgRef', 'FullName'),
            applied_amount: record['AppliedAmount'],
            balance_remaining: record['BalanceRemaining'],
            fob: record['FOB'],
            memo: record['Memo'],
            exchange_rate: record['ExchangeRate'],
            balance_remaining_in_home_currency: record['BalanceRemainingInHomeCurrency'],
            is_to_be_printed: record['IsToBePrinted'],
            is_to_be_emailed: record['IsToBeEmailed'],
            is_tax_included: record['IsTaxIncluded'],
            suggested_discount_amount: record['SuggestedDiscountAmount'],
            suggested_discount_date: record['SuggestedDiscountDate'].to_s,
            other: record['Other'],
            external_guid: record['ExternalGUID'],
            relationships: [
              { object: 'customer', key: 'qbe_id' },
              { object: 'product', key: 'qbe_id', location: 'line_items' }
            ]
          }
        end
      end
    end
  end
end

# TODO: Still need these fields when getting invoices
# <LinkedTxn> <!-- optional, may repeat -->
#         <TxnID >IDTYPE</TxnID> <!-- required -->
#         <!-- TxnType may have one of the following values: ARRefundCreditCard, Bill, BillPaymentCheck, BillPaymentCreditCard, BuildAssembly, Charge, Check, CreditCardCharge, CreditCardCredit, CreditMemo, Deposit, Estimate, InventoryAdjustment, Invoice, ItemReceipt, JournalEntry, LiabilityAdjustment, Paycheck, PayrollLiabilityCheck, PurchaseOrder, ReceivePayment, SalesOrder, SalesReceipt, SalesTaxPaymentCheck, Transfer, VendorCredit, YTDAdjustment -->
#         <TxnType >ENUMTYPE</TxnType> <!-- required -->
#         <TxnDate >DATETYPE</TxnDate> <!-- required -->
#         <RefNumber >STRTYPE</RefNumber> <!-- optional -->
#         <!-- LinkType may have one of the following values: AMTTYPE, QUANTYPE -->
#         <LinkType >ENUMTYPE</LinkType> <!-- optional -->
#         <Amount >AMTTYPE</Amount> <!-- required -->
# </LinkedTxn>
# <!-- BEGIN OR -->
#         <InvoiceLineRet> THIS IS DONE - left it here to show the OR that is sent back
# <!-- OR -->
#         <InvoiceLineGroupRet> <!-- optional -->
#                 <TxnLineID >IDTYPE</TxnLineID> <!-- required -->
#                 <ItemGroupRef> <!-- required -->
#                         <ListID >IDTYPE</ListID> <!-- optional -->
#                         <FullName >STRTYPE</FullName> <!-- optional -->
#                 </ItemGroupRef>
#                 <Desc >STRTYPE</Desc> <!-- optional -->
#                 <Quantity >QUANTYPE</Quantity> <!-- optional -->
#                 <UnitOfMeasure >STRTYPE</UnitOfMeasure> <!-- optional -->
#                 <OverrideUOMSetRef> <!-- optional -->
#                         <ListID >IDTYPE</ListID> <!-- optional -->
#                         <FullName >STRTYPE</FullName> <!-- optional -->
#                 </OverrideUOMSetRef>
#                 <IsPrintItemsInGroup >BOOLTYPE</IsPrintItemsInGroup> <!-- required -->
#                 <TotalAmount >AMTTYPE</TotalAmount> <!-- required -->
#                 <InvoiceLineRet> <!-- optional, may repeat -->
#                         <TxnLineID >IDTYPE</TxnLineID> <!-- required -->
#                         <ItemRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </ItemRef>
#                         <Desc >STRTYPE</Desc> <!-- optional -->
#                         <Quantity >QUANTYPE</Quantity> <!-- optional -->
#                         <UnitOfMeasure >STRTYPE</UnitOfMeasure> <!-- optional -->
#                         <OverrideUOMSetRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </OverrideUOMSetRef>
#                         <!-- BEGIN OR -->
#                                 <Rate >PRICETYPE</Rate> <!-- optional -->
#                         <!-- OR -->
#                                 <RatePercent >PERCENTTYPE</RatePercent> <!-- optional -->
#                         <!-- END OR -->
#                         <ClassRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </ClassRef>
#                         <Amount >AMTTYPE</Amount> <!-- optional -->
#                         <InventorySiteRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </InventorySiteRef>
#                         <InventorySiteLocationRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </InventorySiteLocationRef>
#                         <!-- BEGIN OR -->
#                                 <SerialNumber >STRTYPE</SerialNumber> <!-- optional -->
#                         <!-- OR -->
#                                 <LotNumber >STRTYPE</LotNumber> <!-- optional -->
#                         <!-- END OR -->
#                         <ServiceDate >DATETYPE</ServiceDate> <!-- optional -->
#                         <SalesTaxCodeRef> <!-- optional -->
#                                 <ListID >IDTYPE</ListID> <!-- optional -->
#                                 <FullName >STRTYPE</FullName> <!-- optional -->
#                         </SalesTaxCodeRef>
#                         <Other1 >STRTYPE</Other1> <!-- optional -->
#                         <Other2 >STRTYPE</Other2> <!-- optional -->
#                         <DataExtRet> <!-- optional, may repeat -->
#                                 <OwnerID >GUIDTYPE</OwnerID> <!-- optional -->
#                                 <DataExtName >STRTYPE</DataExtName> <!-- required -->
#                                 <!-- DataExtType may have one of the following values: AMTTYPE, DATETIMETYPE, INTTYPE, PERCENTTYPE, PRICETYPE, QUANTYPE, STR1024TYPE, STR255TYPE -->
#                                 <DataExtType >ENUMTYPE</DataExtType> <!-- required -->
#                                 <DataExtValue >STRTYPE</DataExtValue> <!-- required -->
#                         </DataExtRet>
#                 </InvoiceLineRet>
#                 <DataExtRet> <!-- optional, may repeat -->
#                         <OwnerID >GUIDTYPE</OwnerID> <!-- optional -->
#                         <DataExtName >STRTYPE</DataExtName> <!-- required -->
#                         <!-- DataExtType may have one of the following values: AMTTYPE, DATETIMETYPE, INTTYPE, PERCENTTYPE, PRICETYPE, QUANTYPE, STR1024TYPE, STR255TYPE -->
#                         <DataExtType >ENUMTYPE</DataExtType> <!-- required -->
#                         <DataExtValue >STRTYPE</DataExtValue> <!-- required -->
#                 </DataExtRet>
#         </InvoiceLineGroupRet>
# <!-- END OR -->
# <DataExtRet> <!-- optional, may repeat -->
#         <OwnerID >GUIDTYPE</OwnerID> <!-- optional -->
#         <DataExtName >STRTYPE</DataExtName> <!-- required -->
#         <!-- DataExtType may have one of the following values: AMTTYPE, DATETIMETYPE, INTTYPE, PERCENTTYPE, PRICETYPE, QUANTYPE, STR1024TYPE, STR255TYPE -->
#         <DataExtType >ENUMTYPE</DataExtType> <!-- required -->
#         <DataExtValue >STRTYPE</DataExtValue> <!-- required -->
# </DataExtRet>