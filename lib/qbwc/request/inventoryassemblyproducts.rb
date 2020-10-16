module QBWC
  module Request
    class Inventoryassemblyproducts

      class << self
        def generate_request_insert_update(objects, params = {})
          # We don't add/update assembly items in QBE
          ""
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            if object['list_id'].to_s.empty?
              request << search_xml_by_name(product_identifier(object), session_id)
            else
              request << search_xml_by_id(object['list_id'], session_id)
            end
          end
        end

        def search_xml_by_id(object_id, session_id)
          <<~XML
            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
              <ListID>#{object_id}</ListID>
            </ItemInventoryAssemblyQueryRq>
          XML
        end

        def search_xml_by_name(object_id, session_id)
          <<~XML
            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <NameRangeFilter>
                <FromName>#{object_id}</FromName>
                <ToName>#{object_id}</ToName>
              </NameRangeFilter>
            </ItemInventoryAssemblyQueryRq>
          XML
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params['quickbooks_since']
          session_id = Persistence::Session.save(config, 'polling' => timestamp)
          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          inventory_max_returned = nil
          inventory_max_returned = 10000 if params['return_all'].to_i == 1
          if params['quickbooks_max_returned'] && params['quickbooks_max_returned'] != ""
            inventory_max_returned = params['quickbooks_max_returned']
          end

          <<~XML
            <!-- polling non inventory products -->
            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
              <MaxReturned>#{inventory_max_returned || 50}</MaxReturned>
                #{query_by_date(params, time)}
            </ItemInventoryAssemblyQueryRq>
          XML
        end

        private

        def product_identifier(object)
          object['product_id'] || object['sku'] || object['id']
        end

        def query_by_date(config, time)
          return '' if config['return_all'].to_i == 1

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end
      end
    end
  end
end
