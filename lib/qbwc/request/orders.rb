module QBWC
  module Request
    class Orders
      class << self
        def config
          {
            'quickbooks_income_account'    => 'Inventory Asset',
            'quickbooks_cogs_account'      => 'Inventory Asset',
            'quickbooks_inventory_account' => 'Inventory Asset'
          }
        end

        def generate_request_queries(objects)
          objects.inject("") do |request, object|
            request << self.search_xml(object['id'])
          end
        end

        def generate_request_insert_update(objects, params = {})
          ''
        end

        def search_xml(record_id)
         <<-XML
          <SalesOrderQueryRq>
            <RefNumber>#{record_id}</RefNumber>
            <!-- <RefNumberCaseSensitive>STRTYPE</RefNumberCaseSensitive> -->
            <!-- <MaxReturned>INTTYPE</MaxReturned> -->
            <!-- <OwnerID>GUIDTYPE</OwnerID> -->
          </SalesOrderQueryRq>
          XML
        end
      end
    end
  end
end
