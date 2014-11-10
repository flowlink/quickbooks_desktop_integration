module QBWC
  module Request
    class Products
      attr_reader :result, :records

      def mapped_records
        records.map do |record|
          {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            description: record['SalesDesc'],
            price: record['SalesPrice'],
            cost_price: record['PurchaseCost'],
            available_on: record['TimeModified'],
            income_account_id: record['IncomeAccountRef']['FullName']
          }
        end
      end

      def self.config
        #TODO changed to yml database
        {
          'quickbooks_income_account'    => 'Inventory Asset',
          'quickbooks_cogs_account'      => 'Inventory Asset',
          'quickbooks_inventory_account' => 'Inventory Asset'
        }
      end

      # Return the requests to insert/update for products
      def self.generate_request_insert_update(objects)
        objects.inject("") do |request, object|
          if object[:list_id].present?
            request << self.add_xml_to_send(object)
          else
            request << self.update_xml_to_send(object)
          end
        end
      end

      # Return the requests to query products
      def self.generate_request_queries(objects)
        objects.inject("") do |request, object|
          request << self.search_xml(object['id'])
        end
      end

      def self.search_xml(product_id)
       <<-XML
          <ItemInventoryQueryRq>
            <MaxReturned>50</MaxReturned>
            <NameFilter>
              <MatchCriterion >StartsWith</MatchCriterion>
              <Name>#{product_id}</Name>
            </NameFilter>
          </ItemInventoryQueryRq>
        XML
      end

      def self.add_xml_to_send(product)
        <<-XML
          <ItemInventoryAddRq>
             <ItemInventoryAdd>
                <Name>#{product['id']}</Name>
                <SalesDesc>#{product['description']}</SalesDesc>
                <SalesPrice>#{product['price']}</SalesPrice>
                <IncomeAccountRef>
                   <FullName>#{config['quickbooks_income_account']}</FullName>
                </IncomeAccountRef>
                <PurchaseCost>#{product['cost_price']}</PurchaseCost>
                <COGSAccountRef>
                  <FullName>#{config['quickbooks_cogs_account']}</FullName>
                </COGSAccountRef>
                <AssetAccountRef>
                   <FullName>#{config['quickbooks_inventory_account']}</FullName>
                </AssetAccountRef>
             </ItemInventoryAdd>
          </ItemInventoryAddRq>
        XML
      end

      def self.update_xml_to_send(product)
        <<-XML
          <ItemInventoryModRq>
             <ItemInventoryMod>
                <ListID>#{product['quickbooks_id']}</ListID>
                <EditSequence>#{product['quickbooks_version']}</EditSequence>
                <Name>#{product['id']}</Name>
                <SalesDesc>#{product['description']}</SalesDesc>
                <SalesPrice>#{product['price']}</SalesPrice>
                <IncomeAccountRef>
                   <FullName>#{config['quickbooks_income_account']}</FullName>
                </IncomeAccountRef>
                <PurchaseCost>#{product['cost_price']}</PurchaseCost>
                <COGSAccountRef>
                  <FullName>#{config['quickbooks_cogs_account']}</FullName>
                </COGSAccountRef>
                <AssetAccountRef>
                   <FullName>#{config['quickbooks_inventory_account']}</FullName>
                </AssetAccountRef>
             </ItemInventoryMod>
          </ItemInventoryModRq>
        XML
      end
    end
  end
end
