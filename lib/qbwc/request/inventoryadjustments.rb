module QBWC
  module Request
    class Inventoryadjustments
      class << self
        def generate_request_insert_update(_objects, _params = {})
          # nothing on this class
          ""
        end

        def generate_request_queries(_objects, _params)
          # nothing on this class
          ""
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          session_id = Persistence::Session.save(config, 'polling' => params['quickbooks_since'])

          time = Time.parse(params['quickbooks_since']).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling inventory adjustments -->
            <InventoryAdjustmentQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
                #{limit_returned(params)}
                <ModifiedDateRangeFilter>
                  <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
                </ModifiedDateRangeFilter>
            </InventoryAdjustmentQueryRq>
          XML
        end

        private

        def limit_returned(config)
          puts "Product config for polling: #{config}"
          return '' if config['return_all']
          
          <<~XML
            <MaxReturned>100</MaxReturned>
          XML
        end
      end
    end
  end
end
