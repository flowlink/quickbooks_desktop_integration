module QBWC
  module Request
    class Inventorywithsites

      class << self
        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params['quickbooks_since']
          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          <<~XML
            <ItemSitesQueryRq requestID="#{session_id}">
              <ItemSiteFilter>
                <SiteFilter>
                  <FullName>#{site_name(params)}</FullName>
                </SiteFilter>
              </ItemSiteFilter>
              <MaxReturned>10000</MaxReturned>
              <ActiveStatus>ActiveOnly</ActiveStatus>
            </ItemSitesQueryRq>
          XML
        end

        private

        def site_name(obj)
          obj['quickbooks_site']
        end

      end
    end
  end
end
