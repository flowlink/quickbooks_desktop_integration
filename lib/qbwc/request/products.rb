module QBWC
  module Request
    class Products
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                       end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

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
                  #{product.has_key?('active') ? product_only_touch_xml(product, params) : product_xml(product, params)}
               </ItemInventoryMod>
            </ItemInventoryModRq>
          XML
        end

        def product_only_touch_xml(product, params)
          <<-XML
                  <Name>#{product['id']}</Name>
                  <IsActive>true</IsActive>
          XML
        end

        def product_xml(product, params)
          product = complement_inventory(product)
          <<-XML
              <Name>#{product['id'].split(':').last}</Name>
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

        def polling_others_items_xml(timestamp, config)
          # nothing on this class
          ''
        end
        # TODO Migrating to inventories.rb
        def polling_current_items_xml(timestamp, config)
          session_id = Persistence::Session.save(config, {"polling" => timestamp})

          time = Time.parse(timestamp).in_time_zone "Pacific Time (US & Canada)"

          <<-XML

      <!-- polling products -->
      <ItemInventoryQueryRq requestID="#{session_id}">
       <MaxReturned>100</MaxReturned>
        <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
        <!-- <IncludeRetElement>Name</IncludeRetElement> -->
      </ItemInventoryQueryRq>
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
