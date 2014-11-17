module QBWC
  module Request
    class Products
      def self.config
        {
          'quickbooks_income_account'    => 'Inventory Asset',
          'quickbooks_cogs_account'      => 'Inventory Asset',
          'quickbooks_inventory_account' => 'Inventory Asset'
        }
      end

      # Return the requests to insert/update for products
      def self.generate_request_insert_update(objects, params = {})
        objects.inject("") do |request, object|
          puts "generate_request_insert_update(objects, params = {}): #{object.inspect}"
          session_id = Persistence::Object.new({connection_id: params['connection_id']},{}).save_session(object)
          request << if object[:list_id].to_s.empty?
                       add_xml_to_send(object, config.merge(params), session_id)
                     else
                       update_xml_to_send(object, config.merge(params), session_id)
                     end
        end
      end

      # Return the requests to query products
      def self.generate_request_queries(objects, params)
        objects.inject("") do |request, object|
          session_id = Persistence::Object.new({connection_id: params['connection_id']},{}).save_session(object)
          request << self.search_xml(object.has_key?('product_id') ? object['product_id'] : object['id'], session_id)
        end
      end

      def self.search_xml(product_id, session_id)
       <<-XML
          <ItemInventoryQueryRq requestID="#{session_id}">
            <MaxReturned>100</MaxReturned>
            <NameFilter>
              <MatchCriterion >StartsWith</MatchCriterion>
              <Name>#{product_id}</Name>
            </NameFilter>
          </ItemInventoryQueryRq>
        XML
      end

      def self.add_xml_to_send(product, params, session_id)

        product = complement_inventory(product)
        <<-XML
          <ItemInventoryAddRq requestID="#{session_id}">
             <ItemInventoryAdd>
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
                <QuantityOnHand>#{product['quantity']}</QuantityOnHand>
             </ItemInventoryAdd>
          </ItemInventoryAddRq>
        XML
      end

      def self.update_xml_to_send(product, params, session_id)
        product = complement_inventory(product)

        <<-XML
          <ItemInventoryModRq requestID="#{session_id}">
             <ItemInventoryMod>
                <ListID>#{product['list_id']}</ListID>
                <EditSequence>#{product['edit_sequence']}</EditSequence>
                <Name>#{product['id']}</Name>
                <SalesDesc>#{product['description']}</SalesDesc>
                <SalesPrice>#{product['price']}</SalesPrice>
                <IncomeAccountRef>
                   <FullName>#{params['quickbooks_income_account']}</FullName>
                </IncomeAccountRef>
                <PurchaseCost>#{product['cost_price']}</PurchaseCost>
                <COGSAccountRef>
                  <FullName>#{params['quickbooks_cogs_account']}</FullName>
                </COGSAccountRef>
                <AssetAccountRef>
                   <FullName>#{params['quickbooks_inventory_account']}</FullName>
                </AssetAccountRef>
             </ItemInventoryMod>
          </ItemInventoryModRq>
        XML
      end

      def self.complement_inventory(product)
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
