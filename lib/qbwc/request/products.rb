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
          request << if object[:list_id].to_s.empty?
                       add_xml_to_send(object, config.merge(params))
                     else
                       update_xml_to_send(object, config.merge(params))
                     end
        end
      end

      # Return the requests to query products
      def self.generate_request_queries(objects)
        objects.inject("") do |request, object|
          request << self.search_xml(object.has_key?('product_id') ? object['product_id'] : object['id'])
        end
      end

      def self.search_xml(product_id)
       <<-XML
          <ItemInventoryQueryRq>
            <MaxReturned>100</MaxReturned>
            <NameFilter>
              <MatchCriterion >StartsWith</MatchCriterion>
              <Name>#{product_id}</Name>
            </NameFilter>
          </ItemInventoryQueryRq>
        XML
      end

      def self.add_xml_to_send(product, params)

        product = complement_inventory(product)
        <<-XML
          <ItemInventoryAddRq>
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

      def self.update_xml_to_send(product, params)
        product = complement_inventory(product)

        <<-XML
          <ItemInventoryModRq>
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
                <QuantityOnHand>#{product['quantity']}</QuantityOnHand>
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
