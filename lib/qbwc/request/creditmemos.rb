module QBWC
  module Request
    class Creditmemos
      GENERAL_MAPPING = [
        {qbe_name: "CustomerRef", flowlink_name: "customer_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "PONumber", flowlink_name: "po_number", is_ref: false},
        {qbe_name: "Other", flowlink_name: "other", is_ref: false},
      ]
      EXTERNAL_GUID_MAP = [{qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}]

      class << self

        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object['list_id'].to_s.empty?
                         add_xml_to_send(object, params, session_id, config)
                       else
                         update_xml_to_send(object, params, session_id, config)
                       end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            if object['list_id'] && object['list_id'].to_s.empty?
              request << search_xml_by_name(object['id'], session_id)
            else
              request << search_xml_by_id(object['list_id'], session_id)
            end
          end
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params['quickbooks_since']
          session_id = Persistence::Session.save(config, 'polling' => timestamp)
          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          max_returned = nil
          max_returned = 10000 if params['return_all'].to_i == 1
          if params['quickbooks_max_returned'] && params['quickbooks_max_returned'] != ""
            max_returned = params['quickbooks_max_returned']
          end
          <<~XML
            <CreditMemoQueryRq requestID="#{session_id}">
              <MaxReturned>#{max_returned || 50}</MaxReturned>
              #{query_by_date(params, time)}
            </CreditMemoQueryRq>
          XML

        end


        def add_xml_to_send(object, params, session_id, config)
          <<~XML
            <CreditMemoAddRq requestID="#{session_id}">
              <CreditMemoAdd>
                #{creditmemo object, params, false}
                #{external_guid(object)}
                #{items(object).map { |l| credit_memo_line_add l }.join('')}
              </CreditMemoAdd>
            </CreditMemoAddRq>
          XML
        end

        def update_xml_to_send(object, params, session_id, config)
          <<~XML
            <CreditMemoModRq requestID="#{session_id}">
              <CreditMemoMod>
                <TxnID>#{object['list_id']}</TxnID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                #{creditmemo object, params, true}
                #{items(object).map { |l| credit_memo_line_mod l }.join('')}
              </CreditMemoMod>
            </CreditMemoModRq>
          XML
        end

        def search_xml_by_name(identifier, session_id)
          <<~XML
            <CreditMemoQueryRq requestID="#{session_id}">
              <RefNumberCaseSensitive>#{list_id}</RefNumberCaseSensitive>
              <IncludeLineItems>true</IncludeLineItems>
              <IncludeLinkedTxns>true</IncludeLinkedTxns>
            </CreditMemoQueryRq>
          XML
        end

        def search_xml_by_id(list_id, session_id)
          <<~XML
            <CreditMemoQueryRq requestID="#{session_id}">
              <TxnID>#{list_id}</TxnID>
              <IncludeLineItems>true</IncludeLineItems>
              <IncludeLinkedTxns>true</IncludeLinkedTxns>
            </CreditMemoQueryRq>
          XML
        end

        private

        def external_guid(record)
          return '' unless record['external_guid']

          <<~XML
          <ExternalGUID>#{record['external_guid']}</ExternalGUID>
          XML
        end

        def query_by_date(config, time)
          return '' if config['return_all'].to_i == 1

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end

        def creditmemo(record, params, is_mod)
          puts "Building creditmemo XML for #{record}"
          if record['placed_on'].nil? || record['placed_on'].empty?
            record['placed_on'] = Time.now.to_s
          end

          <<~XML
            #{add_fields(record, GENERAL_MAPPING, params, is_mod)}
          XML
        end

        def add_fields(object, mapping, config, is_mod)
          object = object.with_indifferent_access
          fields = ""
          mapping.each do |map_item|
            next if map_item[:mod_only] && map_item[:mod_only] != is_mod
            next if map_item[:add_only] && map_item[:add_only] == is_mod

            if map_item[:is_ref]
              fields += add_ref_xml(object, map_item, config)
            else
              fields += add_basic_xml(object, map_item)
            end
          end

          fields
        end

        def items(record)
          record['line_items'].to_a.sort_by { |a| a['product_id'] }
        end

        def add_basic_xml(object, mapping)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]
          float_fields = ['price', 'cost']

          return '' if flowlink_field.nil? || flowlink_field == ""

          flowlink_field = '%.2f' % flowlink_field.to_f if float_fields.include?(mapping[:flowlink_name])

          "<#{qbe_field_name}>#{flowlink_field}</#{qbe_field_name}>"
        end

        def add_ref_xml(object, mapping, config)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]

          if flowlink_field.respond_to?(:has_key?) && flowlink_field['list_id']
            return "<#{qbe_field_name}><ListID>#{flowlink_field['list_id']}</ListID></#{qbe_field_name}>"
          end
          full_name = flowlink_field ||
                                config[mapping[:flowlink_name].to_sym] ||
                                config["quickbooks_#{mapping[:flowlink_name]}".to_sym]

          return '' if full_name.nil? || full_name == ""
          "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end

        def credit_memo_line_add(line)
          <<~XML
            <CreditMemoLineAdd>
              #{credit_memo_line(line)}
            </CreditMemoLineAdd>
          XML
        end

        def credit_memo_line_mod(line)
          <<~XML
            <CreditMemoLineMod>
              <TxnLineID>#{line['txn_line_id'] || -1}</TxnLineID>
              #{credit_memo_line(line)}
            </CreditMemoLineMod>
          XML
        end

        def credit_memo_line(line)
          <<~XML
            <ItemRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemRef>
            <Desc>#{line['name']}</Desc>
            #{quantity(line)}
            #{rate_line(line)}
            #{class_ref_for_credit_memo_line(line)}
            #{amount_line(line)}
            #{inventory_site(line)}
            #{tax_code_line(line)}
          XML
        end

        def quantity(line)
          return '' if line['quantity'].to_f == 0.0

          "<Quantity>#{line['quantity']}</Quantity>"
        end

        def rate_line(line)
          return '' if !line['amount'].to_s.empty? || line['use_amount'] == true

          <<~XML
            <Rate>#{'%.2f' % price(line).to_f}</Rate>
          XML
        end

        def class_ref_for_credit_memo_line(line)
          return '' unless line['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{line['class_name']}</FullName>
            </ClassRef>
          XML
        end

        def amount_line(line)
          return '' if rate_line(line) != ''

          amount = line['amount'] || price(line)
          return '' unless amount

          <<~XML
            <Amount>#{'%.2f' % amount.to_f}</Amount>
          XML
        end

        def inventory_site(line)
          return '' unless line['inventory_site_name']

          <<~XML
            <InventorySiteRef>
              <FullName>#{line['inventory_site_name']}</FullName>
            </InventorySiteRef>
          XML
        end

        def tax_code_line(line)
          return '' if line['tax_code_id'].to_s.empty?

          <<~XML
            <SalesTaxCodeRef>
              <FullName>#{line['tax_code_id']}</FullName>
            </SalesTaxCodeRef>
          XML
        end

        def price(line)
          line['line_item_price'] || line['price']
        end

      end

    end
  end
end
