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

          if site_name(params) == ''
            all_sites(session_id)
          else
            site_name_filter(session_id, params)
          end
        end

        def site_name_filter(session_id, params)
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

        def all_sites(session_id)
          <<~XML
            <ItemSitesQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <ActiveStatus>ActiveOnly</ActiveStatus>
            </ItemSitesQueryRq>
          XML
        end

        def site_name(obj)
          obj['quickbooks_site']
        end

      end
    end
  end
end
