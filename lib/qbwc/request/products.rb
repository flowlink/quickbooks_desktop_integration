module QBWC
  module Request
    class Products
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                       end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << self.search_xml(object.has_key?('product_id') ? object['product_id'] : object['id'], session_id)
          end
        end

        def search_xml(product_id, session_id)
         <<-XML
            <ItemInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
              <NameRangeFilter>
                <FromName>#{product_id}</FromName>
                <ToName>#{product_id}</ToName>
              </NameRangeFilter>
            </ItemInventoryQueryRq>
          XML
        end

        def add_xml_to_send(product, params, session_id)
          <<-XML
            <ItemInventoryAddRq requestID="#{session_id}">
               <ItemInventoryAdd>
                #{product_xml(product, params)}
               </ItemInventoryAdd>
            </ItemInventoryAddRq>
          XML
        end

        def update_xml_to_send(product, params, session_id)
          <<-XML
            <ItemInventoryModRq requestID="#{session_id}">
               <ItemInventoryMod>
                  <ListID>#{product['list_id']}</ListID>
                  <EditSequence>#{product['edit_sequence']}</EditSequence>
                  #{product_xml(product, params)}
               </ItemInventoryMod>
            </ItemInventoryModRq>
          XML
        end

        def product_xml(product, params)
          product = complement_inventory(product)
          <<-XML
              <Name>#{product['id']}</Name>
              <SalesDesc>#{product['description']}</SalesDesc>
              <SalesPrice>#{product['price']}</SalesPrice>
              <IncomeAccountRef>
                 <FullName>#{params['quickbooks_income_account']}</FullName>
              </IncomeAccountRef>
              <PurchaseCost>#{params['cost_price']}</PurchaseCost>
              <COGSAccountRef>
                <FullName>#{params['quickbooks_cogs_account']}</FullName>
              </COGSAccountRef>
              <AssetAccountRef>
                 <FullName>#{params['quickbooks_inventory_account']}</FullName>
              </AssetAccountRef>
          XML
        end

        def complement_inventory(product)
          if product.has_key?('product_id')
            product['id']          = product['product_id']
            product['description'] = product['product_id']
            product['price']       = 0
            product['cost_price']  = 0
          else
            product['quantity'] = 0
          end

          product
        end
      end
    end
  end
end
