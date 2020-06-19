module QBWC
  module Request
    class Creditmemos
      GENERAL_MAPPING = [
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
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

            if object['list_id'].to_s.empty?
              request << search_xml_by_name(object['name'], session_id)
            else
              request << search_xml_by_id(object['id'], session_id)
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

        private

        def add_xml_to_send(object, params, session_id, config)
        end

        def update_xml_to_send(object, params, session_id, config)
        end

        def search_xml_by_name(identifier, session_id)
        end

        def search_xml_by_id(list_id, session_id)
          <<~XML
            <CreditMemoQueryRq requestID="#{session_id}">
              <RefNumberCaseSensitive>#{list_id}</RefNumberCaseSensitive>
              <IncludeLineItems>true</IncludeLineItems>
              <IncludeLinkedTxns>true</IncludeLinkedTxns>
            </CreditMemoQueryRq>
          XML
        end

      end

    end
  end
end
