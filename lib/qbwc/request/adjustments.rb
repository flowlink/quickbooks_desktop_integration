module QBWC
  module Request
    # We will not remove this class, because the customer probably will change their mind and we will start to use again
    class Adjustments
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            if object[:list_id].to_s.empty?
              request = add_xml_to_send(object, params, session_id)
            else
              request           = ''
              objects_to_update = [{ adjustments: {
                id: object['id'],
                list_id: object['list_id'],
                edit_sequence: object['edit_sequence']
              }
                                   }]
              Persistence::Object.update_statuses(params, objects_to_update)
            end
            request
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object.key?('product_id') ? object['product_id'] : object['id'], session_id)
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
                   <FullName>#{account(adjustment, params)}</FullName>
                 </AccountRef>
               </SalesOrPurchase>
          XML
        end

        def account(adjustment, params)
          if adjustment['id'].downcase.match(/discount/)
            params['quickbooks_other_charge_discount_account']
          elsif adjustment['id'].downcase.match(/shipping/)
            params['quickbooks_other_charge_shipping_account']
          else
            params['quickbooks_other_charge_tax_account']
         end
        end

        def adjustment_product_from_qb(adjustment_name, params)
          if adjustment_name.downcase.match(/discount/)
            params['quickbooks_discount_item']
          elsif adjustment_name.downcase.match(/shipping/)
            params['quickbooks_shipping_item']
          elsif adjustment_name.downcase.match(/tax/)
            params['quickbooks_tax_item']
         end
        end
      end
    end
  end
end
