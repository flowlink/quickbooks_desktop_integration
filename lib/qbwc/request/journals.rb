module QBWC
  module Request
    class Journals
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
          if object['list_id'].to_s.empty? && object['action'] != "DELETE"
            puts "ADD"
            add_xml_to_send(object, params, session_id)
          elsif object['action'] == "DELETE"
            puts "DELETE"
            delete_xml_to_send(object, session_id)
          elsif object['action'] == "UPDATE"
            puts "UPDATE"
            update_xml_to_send(object, params, session_id)
          else
            raise "Valid Action not given: please use ADD, UPDATE, or DELETE action. If using DELETE, journal must exist already."
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object['id'], session_id)
          end
        end

        def search_xml(journal_id, session_id)
          <<-XML
            <JournalEntryQueryRq requestID="#{session_id}">
              <RefNumber>#{journal_id}</RefNumber>
            </JournalEntryQueryRq>
          XML
        end

        def add_xml_to_send(journal, params, session_id)
          <<-XML
            <JournalEntryAddRq requestID="#{session_id}">
               <JournalEntryAdd>
                #{journal_xml(journal, params, false)}
               </JournalEntryAdd>
            </JournalEntryAddRq>
          XML
        end

        def update_xml_to_send(journal, params, session_id)
          # You NEED the edit_sequence to update
          # If you have the wrong edit_sequence (AKA someone manually updated since create/update) it will fail
          <<-XML
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
          <<-XML
          <TxnDelRq requestID="#{session_id}">
            <TxnDelType >JournalEntry</TxnDelType>
            <TxnID>#{journal['list_id']}</TxnID>
          </TxnDelRq>
          XML
        end

        def journal_xml(journal, params, isAdjustment)
          credit_lines, debit_lines = split_lines(journal['line_items'])
          <<-XML
              <TxnDate>#{Time.parse(journal['journal_date']).to_date}</TxnDate>
              <RefNumber>#{journal['id']}</RefNumber>
              <IsAdjustment>#{isAdjustment}</IsAdjustment>
              #{debit_lines.map { |debit| build_debit_line(debit) }.join('')}
              #{credit_lines.map { |credit| build_credit_line(credit) }.join('')}
          XML
        end

        def split_lines(items)
          credit_items = items.select { |item| item['debit'].to_f == 0.0 }
          debit_items = items.select { |item| item['credit'].to_f == 0.0 }

          [credit_items, debit_items]
        end

        def build_debit_line(item)
          <<-XML
            <JournalDebitLine>
              #{fill_line_item(item, item['debit'])}
            </JournalDebitLine>
          XML
        end

        def build_credit_line(item)
          <<-XML
            <JournalCreditLine>
              #{fill_line_item(item, item['credit'])}
            </JournalCreditLine>
          XML
        end

        def fill_line_item(item, amount)
          <<-XML
            #{item['line_id'] ? "<TxnLineID>#{item['line_id']}</TxnLineID>" : ''}
            <AccountRef>
                <FullName>#{item['account_description']}</FullName>
            </AccountRef>
            <Amount>#{amount.to_f.to_s}</Amount>
            <Memo>#{item['description']}</Memo>
            #{item['customer'] ? fill_customer(item['customer']) : ''}
            #{item['class'] ? fill_class(item['class']) : ''}
          XML
        end

        def fill_customer(name)
          <<-XML
            <EntityRef>
                <FullName>#{name}</FullName>
            </EntityRef>
          XML
        end

        def fill_class(name)
          <<-XML
            <ClassRef>
                <FullName>#{name}</FullName>
            </ClassRef>
          XML
        end
      end
    end
  end
end
