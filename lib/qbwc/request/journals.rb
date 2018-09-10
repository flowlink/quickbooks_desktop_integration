module QBWC
  module Request
    class Journals
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
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
                #{journal_xml(journal, params)}
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
                  #{journal_xml(journal, params)}
               </JournalEntryMod>
            </JournalEntryModRq>
          XML
        end

        def journal_xml(journal, params)
          <<-XML
              <TxnDate>#{journal['journal_date']}</TxnDate>
              <RefNumber>#{journal['id']}</RefNumber>
              <IsAdjustment>false</IsAdjustment>
              <IsHomeCurrencyAdjustment>true</IsHomeCurrencyAdjustment>
              #{journal['line_items'].map { |j| journal_line_items j }.join('')}
          XML
        end

        def journal_line_items(item)
          if item['credit'].to_f == 0.0
            <<-XML
              <JournalDebitLine>
                #{fill_line_item(item, item['debit'])}
              </JournalDebitLine>
            XML
          else
            <<-XML
              <JournalCreditLine>
                #{fill_line_item(item, item['credit'])}
              </JournalCreditLine>
            XML
          end
        end

        def fill_line_item(item, amount)
          <<-XML
            <!-- TxnLineID is required for update. Might need to be set to -1 on create?? -->
            #{item['line_id'] ? "<TxnLineID>#{item['line_id']}</TxnLineID>" : ''}
            <AccountRef>
                <!-- <ListID>IDTYPE</ListID> -->
                <FullName>#{item['account_description']}</FullName>
            </AccountRef>
            <Amount>#{amount}</Amount>
            <Memo>#{item['description']}</Memo>
            #{item['customer'] ? fill_customer(item['customer']) : ''}
            #{item['class'] ? fill_class(item['class']) : ''}
            <!-- BillableStatus may have one of the following values: Billable, NotBillable, HasBeenBilled -->
            <BillableStatus>'Billable'</BillableStatus>
          XML
        end

        def fill_customer(name)
          <<-XML
            <EntityRef>
                <!-- <ListID>IDTYPE</ListID> -->
                <FullName>#{name}</FullName>
            </EntityRef>
          XML
        end

        def fill_class(name)
          <<-XML
            <ClassRef>
                <!-- <ListID>IDTYPE</ListID> -->
                <FullName>#{name}</FullName>
            </ClassRef>
          XML
        end
      end
    end
  end
end
