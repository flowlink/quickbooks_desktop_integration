module QBWC
  module Request
    class Otherchargeproducts

      class << self

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
            <ItemOtherChargeQueryRq requestID="#{session_id}">
              <MaxReturned>#{inventory_max_returned || 50}</MaxReturned>
              #{query_by_date(params, time)}
            </ItemOtherChargeQueryRq>
          XML
        end

        private

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
