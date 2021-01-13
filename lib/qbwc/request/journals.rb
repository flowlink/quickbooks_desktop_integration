require 'time'

module QBWC
  module Request
    class Journals
      LINE_MISSING_ZERO_ERROR ||= "Both the credit and debit amounts are non-zero. Journal lines must contain at least one credit or debit amount of $0.0."
      MAPPING_ONE = [
        {qbe_name: "TxnDate", flowlink_name: "transaction_date", is_ref: false},
        {qbe_name: "RefNumber", flowlink_name: "id", is_ref: false},
        {qbe_name: "IsAdjustment", flowlink_name: "is_mod", is_ref: false},
        {qbe_name: "IsHomeCurrencyAdjustment", flowlink_name: "is_home_currency_adjustment", is_ref: false},
        {qbe_name: "IsAmountsEnteredInHomeCurrency", flowlink_name: "is_amounts_entered_in_home_currency", is_ref: false},
        {qbe_name: "CurrencyRef", flowlink_name: "currency_name", is_ref: true},
        {qbe_name: "ExchangeRate", flowlink_name: "exchange_rate", is_ref: false},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}
      ]

      LINE_MAPPING = [
        {qbe_name: "TxnLineID", flowlink_name: "line_id", is_ref: false},
        {qbe_name: "JournalLineType", flowlink_name: "line_type", is_ref: false, mod_only: true},
        {qbe_name: "AccountRef", flowlink_name: "account_name", is_ref: true},
        {qbe_name: "Amount", flowlink_name: "amount", is_ref: false},
        {qbe_name: "Memo", flowlink_name: "description", is_ref: false},
        {qbe_name: "EntityRef", flowlink_name: "customer_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ItemSalesTaxRef", flowlink_name: "item_sales_tax_name", is_ref: true},
        {qbe_name: "BillableStatus", flowlink_name: "billable_status", is_ref: false}
      ]

      BILLABLE_STATUS = ["Billable", "NotBillable", "HasBeenBilled"]

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            request << decide_action_and_build_request(object, params, session_id)
          end
        end

        def decide_action_and_build_request(object, params, session_id)
          return build_request_by_action(object, params, session_id) if object['action']

          return add_xml_to_send(object, params, session_id) if object[:list_id].to_s.empty?

          update_xml_to_send(object, params, session_id)
        end

        def build_request_by_action(object, params, session_id)
          add_or_update = object['action'] == "ADD" || object['action'] == "UPDATE"

          if add_or_update
            return add_xml_to_send(object, params, session_id) if object['list_id'].to_s.empty?
            return "#{delete_xml_to_send(object, session_id)}#{add_xml_to_send(object, params, session_id)}"
          else
            return delete_xml_to_send(object, session_id) if object['action'] == "DELETE"
          end

          # if object['list_id'].to_s.empty?
          #   return add_xml_to_send(object, params, session_id) if add_or_update
          # else
          #   if add_or_update
          #     return "#{delete_xml_to_send(object, session_id)}#{add_xml_to_send(object, params, session_id)}"
          #   end
          #   return delete_xml_to_send(object, session_id) if object['action'] == "DELETE"
          # end

          # raise "Valid Action not given for object #{object}: please use ADD, UPDATE, or DELETE action. If using DELETE, journal must exist already."
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object['id'], session_id)
          end
        end

        def search_xml(journal_id, session_id)
          <<~XML
            <JournalEntryQueryRq requestID="#{session_id}">
              <RefNumber>#{journal_id}</RefNumber>
            </JournalEntryQueryRq>
          XML
        end

        def add_xml_to_send(journal, params, session_id)
          <<~XML
            <JournalEntryAddRq requestID="#{session_id}">
              <JournalEntryAdd>
              #{journal_xml(journal, params, false)}
              </JournalEntryAdd>
            </JournalEntryAddRq>
          XML
        end

        def update_xml_to_send(journal, params, session_id)
          <<~XML
            <JournalEntryModRq requestID="#{session_id}">
              <JournalEntryMod>
                <TxnID>#{journal['list_id']}</TxnID>
                <EditSequence>#{journal['edit_sequence']}</EditSequence>
                #{journal_xml(journal, params, true)}
              </JournalEntryMod>
            </JournalEntryModRq>
          XML
        end

        def delete_xml_to_send(journal, session_id)
          <<~XML
            <TxnDelRq requestID="#{session_id}">
              <TxnDelType>JournalEntry</TxnDelType>
              <TxnID>#{journal['list_id']}</TxnID>
            </TxnDelRq>
          XML
        end

        def journal_xml(journal, config, is_mod)
          object = pre_mapping_logic(journal, is_mod)

          <<~XML
            #{add_fields(object, MAPPING_ONE, config, is_mod)}
            #{build_debit_lines(object, config, is_mod)}
            #{build_credit_lines(object, config, is_mod)}
          XML
        end

        def build_debit_lines(object, config, is_mod)
          object['debit_lines'].map do |debit_line|
            <<~XML
              <JournalDebitLine>
                #{add_fields(debit_line, LINE_MAPPING, config, is_mod)}
              </JournalDebitLine>
            XML
          end.join('')
        end

        def build_credit_lines(object, config, is_mod)
          object['credit_lines'].map do |credit_line|
            <<~XML
              <JournalCreditLine>
                #{add_fields(credit_line, LINE_MAPPING, config, is_mod)}
              </JournalCreditLine>
            XML
          end.join('')
        end

        private

        def pre_mapping_logic(initial_object, is_mod)
          object = initial_object

          credit_lines, debit_lines = setup_lines(initial_object['line_items'], is_mod)
          object['credit_lines'] = credit_lines
          object['debit_lines'] = debit_lines
          
          object["transaction_date"] = nil
          if initial_object['journal_date'] && initial_object['journal_date'] != ""
            object["transaction_date"] = Time.parse(initial_object['journal_date']).to_date.to_s
          end
          
          object["is_mod"] = is_mod

          object
        end

        def setup_lines(lines, is_mod)
          credit_lines = []
          debit_lines = []

          lines.each do |line|
            line['billable_status'] = nil unless BILLABLE_STATUS.include?(line['billable_status'])
            line["line_id"] = -1 if is_mod && is_missing_line_id(line)
            line["account_name"] = line["account_description"] unless line["account_name"]
            line["class_name"] = line["class"] unless line["class_name"]
            line["customer_name"] = line["customer"] unless line["customer_name"]

            if line['debit'].to_f == 0.0
              line["line_type"] = "Credit"
              line["amount"] = '%.2f' % line['credit'].to_f
              credit_lines << line
            elsif line['credit'].to_f == 0.0
              line["amount"] = '%.2f' % line['debit'].to_f
              line["line_type"] = "Debit"
              debit_lines << line
            else
              raise LINE_MISSING_ZERO_ERROR
            end
          end

          [credit_lines, debit_lines]
        end

        def is_missing_line_id(line)
          line["line_id"].nil? || line["line_id"] == ''
        end

        def add_fields(object, mapping, config, is_mod)
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

        def add_basic_xml(object, mapping)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]
          float_fields = ['price', 'cost', 'amount']

          return '' if flowlink_field.nil?

          if flowlink_field != "" && float_fields.include?(mapping[:flowlink_name])
            flowlink_field = '%.2f' % flowlink_field.to_f
          end

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

          return '' if full_name.nil?
          "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end
      end
    end
  end
end
