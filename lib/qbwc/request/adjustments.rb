module QBWC
  module Request
    class Adjustments
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            if object[:list_id].to_s.empty?
              request = add_xml_to_send(object, params, session_id)
            else
              request           = ''
              objects_to_update = [{ :adjustments => {
                                             :id            => object['id'],
                                             :list_id       => object['list_id'],
                                             :edit_sequence => object['edit_sequence']
                                            }
                                   }]
              Persistence::Object.update_statuses(params, objects_to_update)
            end
            request
          end
        end

        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << self.search_xml(object.has_key?('product_id') ? object['product_id'] : object['id'], session_id)
          end
        end

        def search_xml(adjustment_id, session_id)
         <<-XML
            <ItemOtherChargeQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
              <NameRangeFilter>
                <FromName>#{adjustment_id}</FromName>
                <ToName>#{adjustment_id}</ToName>
              </NameRangeFilter>
            </ItemOtherChargeQueryRq>
          XML
        end

        def add_xml_to_send(adjustment, params, session_id)
          <<-XML
            <ItemOtherChargeAddRq requestID="#{session_id}">
               <ItemOtherChargeAdd>
                #{adjustment_xml(adjustment, params)}
               </ItemOtherChargeAdd>
            </ItemOtherChargeAddRq>
          XML
        end

        def adjustment_xml(adjustment, params)
          <<-XML
               <Name>#{adjustment['id']}</Name>
               <SalesOrPurchase>
                 <Desc>#{adjustment['description']}</Desc>
                 <AccountRef>
                   <FullName>#{params['quickbooks_other_charge_account']}</FullName>
                 </AccountRef>
               </SalesOrPurchase>
          XML
        end
      end
    end
  end
end
