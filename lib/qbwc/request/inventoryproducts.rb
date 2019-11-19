module QBWC
  module Request
    class Inventoryproducts

      class << self
        def generate_request_insert_update(objects, params = {})
          # nothing on this class - find me in qbwc/request/products.rb
          ""
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ""
        end

        def generate_request_queries(objects, params)
          # nothing on this class - find me in qbwc/request/products.rb
          ""
        end

        def polling_current_items_xml(params, config)
          timestamp = params
          timestamp = params['quickbooks_since'] if params['return_all']

          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <ItemInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
              #{query_by_date(params, time)}
            </ItemInventoryQueryRq>
          XML
        end

        def query_by_date(config, time)
          puts "Product config for polling: #{config}"
          return '' if config['return_all']

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end
      end
    end
  end
end

