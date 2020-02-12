module QBWC
  module Request
    class Customers

      MAPPING_ONE = [
        {qbe_name: "VendorRef", flowlink_name: "vendor_name", is_ref: true}
      ]
            
      ADDRESS_MAP = [
        {qbe_name: "Addr1", flowlink_name: "address1", is_ref: false},
        {qbe_name: "Addr2", flowlink_name: "address2", is_ref: false},
        {qbe_name: "Addr3", flowlink_name: "address3", is_ref: false},
        {qbe_name: "Addr4", flowlink_name: "address4", is_ref: false},
        {qbe_name: "Addr5", flowlink_name: "address5", is_ref: false},
        {qbe_name: "City", flowlink_name: "city", is_ref: false},
        {qbe_name: "State", flowlink_name: "state", is_ref: false},
        {qbe_name: "PostalCode", flowlink_name: "zipcode", is_ref: false},
        {qbe_name: "Country", flowlink_name: "country", is_ref: false},
        {qbe_name: "Note", flowlink_name: "note", is_ref: false}
      ]

      MAPPING_TWO = [
        {qbe_name: "APAccountRef", flowlink_name: "ap_account_name", is_ref: true},
        {qbe_name: "TxnDate", flowlink_name: "placed_on", is_ref: false},
        {qbe_name: "DueDate", flowlink_name: "due_date", is_ref: false},
        {qbe_name: "RefNumber", flowlink_name: "id", is_ref: false},
        {qbe_name: "TermsRef", flowlink_name: "terms", is_ref: true},
        {qbe_name: "Memo", flowlink_name: "memo", is_ref: false},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_sales_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "ExchangeRate", flowlink_name: "exchange_rate", is_ref: false},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true},
        {qbe_name: "LinkToTxnID", flowlink_name: "qbe_transaction_id", is_ref: false, add_only: true},
        {qbe_name: "ClearExpenseLines", flowlink_name: "clear_qbe_expense_lines", is_ref: false}
      ]

      EXPENSE_LINE_MAPPING = [
        {qbe_name: "TxnLineID", flowlink_name: "qbe_line_id", is_ref: false},
        {qbe_name: "AccountRef", flowlink_name: "account_name", is_ref: true},
        {qbe_name: "Amount", flowlink_name: "amount", is_ref: false},
        {qbe_name: "Memo", flowlink_name: "memo", is_ref: false},
        {qbe_name: "CustomerRef", flowlink_name: "customer_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "BillableStatus", flowlink_name: "billable_status", is_ref: false},
        {qbe_name: "SalesRepRef", flowlink_name: "sales_rep_name", is_ref: true}
      ]

      MAPPING_THREE = [
        {qbe_name: "ClearItemLines", flowlink_name: "clear_qbe_item_lines", is_ref: false}
      ]

      LINE_MAPPING_ONE = [
        {qbe_name: "TxnLineID", flowlink_name: "qbe_line_id", is_ref: false},
        {qbe_name: "ItemRef", flowlink_name: "product_id", is_ref: true},
        {qbe_name: "InventorySiteRef", flowlink_name: "inventory_site_name", is_ref: true},
        {qbe_name: "InventorySiteLocationRef", flowlink_name: "inventory_site_location_name", is_ref: true},
        {qbe_name: "SerialNumber", flowlink_name: "serial_number", is_ref: false},
        {qbe_name: "LotNumber", flowlink_name: "lot_number", is_ref: false},
        {qbe_name: "Desc", flowlink_name: "description", is_ref: false},
        {qbe_name: "Quantity", flowlink_name: "quantity", is_ref: false},
        {qbe_name: "UnitOfMeasure", flowlink_name: "unit_of_measure", is_ref: false},
        {qbe_name: "OverrideUOMSetRef", flowlink_name: "override_uom_set_name", is_ref: false},
        {qbe_name: "Cost", flowlink_name: "cost", is_ref: false},
        {qbe_name: "Amount", flowlink_name: "amount", is_ref: false},
        {qbe_name: "CustomerRef", flowlink_name: "customer_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "BillableStatus", flowlink_name: "billable_status", is_ref: false},
        {qbe_name: "OverrideItemAccountRef", flowlink_name: "override_item_account_name", is_ref: true}
      ]

      LINE_LINK_TO_TXN_MAPPING = [
        {qbe_name: "TxnID", flowlink_name: "qbe_transaction_id", is_ref: false, add_only: true},
        {qbe_name: "TxnLineID", flowlink_name: "qbe_transaction_line_id", is_ref: false, add_only: true}
      ]

      LINE_MAPPING_TWO = [
        {qbe_name: "SalesRepRef", flowlink_name: "sales_rep_name", is_ref: true}
      ]
 
      BILLABLE_STATUSES = ['Billable', 'NotBillable', 'HasBeenBilled']

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty? 
                                    add_xml_to_send(object, session_id, config) 
                                  else
                                    update_xml_to_send(object, session_id, config))
                                  end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object['id'], session_id)
          end
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(timestamp, config)
          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <BillQueryRq requestID="#{session_id}">
            <MaxReturned>100</MaxReturned>
              <ModifiedDateRangeFilter>
                #{query_by_date(config, time)}
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
            </BillQueryRq>
          XML
        end

        def query_by_date(config, time)
          return '' if config['return_all']

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end

        def search_xml(order_id, session_id)
          <<~XML
            <BillQueryRq requestID="#{session_id}">
              <RefNumberCaseSensitive>#{order_id}</RefNumberCaseSensitive>
              <IncludeLineItems>true</IncludeLineItems>
            </BillQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id, config)
          <<~XML
            <BillAddRq requestID="#{session_id}">
              <BillAdd>
                #{bill_xml(object, config, false)}
              </BillAdd>
            </BillAddRq>
          XML
        end

        def update_xml_to_send(object, session_id, config)
          <<~XML
            <BillModRq requestID="#{session_id}">
              <BillMod>
                <ListID>#{object['list_id']}</ListID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                #{bill_xml(object, config, true)}
              </BillMod>
            </BillModRq>
          XML
        end

        private

        def bill_xml(initial_object, config, is_mod)
          object = pre_mapping_logic(initial_object, is_mod)

          <<~XML
            #{add_fields(object, MAPPING_ONE, config, is_mod)}
            <VendorAddress>
              #{add_fields(object['vendor_address'], ADDRESS_MAP, config, is_mod) if object['vendor_address']}
            </VendorAddress>
            #{add_fields(object, MAPPING_TWO, config, is_mod)}
            #{expense_lines(object, config, is_mod)}
            #{add_fields(object, MAPPING_THREE, config, is_mod)}
            #{is_mod ? "<ItemLineMod>" : "<ItemLineAdd>"}
              #{object['line_items'].map {|line| bill_line(line, config, is_mod)} }
            #{is_mod ? "</ItemLineMod>" : "</ItemLineAdd>"}
          XML
        end

        def expense_lines(object, config, is_mod)
          return "" unless object['expense_lines'] && object['expense_lines'].is_a?(Array)
          
          fields = ""
          object['expense_lines'].each do |line|
            line['qbe_line_id'] = is_mod ? -1 : nil;

            fields += <<~XML
              #{is_mod ? "<ExpenseLineMod>" : "<ExpenseLineAdd>"}
                #{add_fields(object, EXPENSE_LINE_MAPPING, config, is_mod)}
              #{is_mod ? "</ExpenseLineMod>" : "</ExpenseLineAdd>"}
            XML
          end

          fields
        end

        def bill_line(line, config, is_mod)
          # TODO: Add GroupLine option here
          line['lot_number'] = nil if line['serial_number']
          line['qbe_line_id'] = is_mod ? -1 : nil;
          line['override_uom_set_name'] = nil unless is_mod

          <<~XML
            #{add_fields(line, LINE_MAPPING_ONE, config, is_mod)}
            #{link_to_txn(line, config, is_mod) unless is_mod}
            #{add_fields(line, LINE_MAPPING_TWO, config, is_mod)}
          XML
        end

        def link_to_txn(line, config, is_mod)
          <<~XML
            </LinkToTxn>
              #{add_fields(line, LINE_LINK_TO_TXN_MAPPING, config, is_mod)}
            </LinkToTxn>
          XML
        end

        def pre_mapping_logic(initial_object, is_mod)
          object = initial_object

          object['clear_qbe_expense_lines'] = nil unless is_mod
          object['clear_qbe_item_lines'] = nil unless is_mod

          object['line_items'].each {|line| line['amount'] = price(line) }

          object['billable_status'] = nil unless BILLABLE_STATUSES.include?(object['billable_status'])

          object
        end

        def price(line)
          line['amount'] || line['line_item_price'] || line['price']
        end

        def add_fields(object, mapping, config, is_mod)
          fields = ""
          mapping.each do |map_item|
            return "" if object[:mod_only] && object[:mod_only] != is_mod
            return "" if object[:add_only] && object[:add_only] == is_mod

            if map_item[:is_ref]
              fields += add_ref_xml(object, map_item, config)
            else
              fields += add_basic_xml(object, map_item)
            end
          end

          fields
        end

        def add_basic_xml(object, mapping)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]
          float_fields = ['price', 'cost']
          date_fields = ['updated_at', 'created_at', 'due_date', 'placed_on']

          return '' if flowlink_field.nil?

          flowlink_field = '%.2f' % flowlink_field.to_f if float_fields.include?(mapping[:flowlink_name])
          flowlink_field = Time.parse(flowlink_field).to_date if date_fields.include?(mapping[:flowlink_name])

          "<#{qbe_field_name}>#{flowlink_field}</#{qbe_field_name}>"
        end

        def add_ref_xml(object, mapping, config)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]

          if flowlink_field.respond_to?(:has_key?) && flowlink_field['list_id']
            return "<#{qbe_field_name}><ListID>#{flowlink_field['list_id']}</ListID></#{qbe_field_name}>"
          end
          full_name = flowlink_field ||
                                config[mapping[:flowlink_name]] ||
                                config["quickbooks_#{mapping[:flowlink_name]}"]

          full_name.nil? ? "" : "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end
      end
    end
  end
end
