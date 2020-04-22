module QBWC
  module Request
    class Inventorywithsites

      class << self
        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params
          timestamp = params['quickbooks_since'] if params['return_all']

          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <ItemSitesQueryRq requestID="#{session_id}">
              <ItemTypeFilter>Inventory</ItemTypeFilter>
              <MaxReturned>10000</MaxReturned>
              <ActiveStatus>ActiveOnly</ActiveStatus>
            </ItemSitesQueryRq>
          XML
        end


      end
    end
  end
end
