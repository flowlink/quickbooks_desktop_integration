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
          # objects.inject("") do |request, object|
          #   request << search_xml(object['id'])
          # end
          ''
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, config.merge(params))
                       else
                         update_xml_to_send(object, config.merge(params))
                       end
          end
        end

        private
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

          def add_xml_to_send(record, params= {})
            <<-XML
              <SalesOrderAddRq>
                <!-- <SalesOrderAdd defMacro="what is this defMacro thing? could be useful?"> -->
                <SalesOrderAdd>
                  <!-- required -->
                  <CustomerRef>
                    <ListID>80000009-1415929219</ListID>
                    <!-- <FullName>Joe Smith</FullName> -->
                  </CustomerRef>
                  <RefNumber>#{record['id']}</RefNumber>
                  <!-- <BillAddress> -->
                  <!--   <Addr1>#{record['billing_address']['address1']}</Addr1> -->
                  <!--   <Addr2>#{record['billing_address']['address2']}</Addr2> -->
                  <!--   <City>#{record['billing_address']['city']}</City> -->
                  <!--   <State>#{record['billing_address']['state']}</State> -->
                  <!--   <PostalCode>#{record['billing_address']['zipcode']}</PostalCode> -->
                  <!--   <Country>#{record['billing_address']['country']}</Country> -->
                  <!-- </BillAddress> -->
                  <!-- <ShipAddress> -->
                  <!--   <Addr1>#{record['shipping_address']['address1']}</Addr1> -->
                  <!--   <Addr2>#{record['shipping_address']['address2']}</Addr2> -->
                  <!--   <City>#{record['shipping_address']['city']}</City> -->
                  <!--   <State>#{record['shipping_address']['state']}</State> -->
                  <!--   <PostalCode>#{record['shipping_address']['zipcode']}</PostalCode> -->
                  <!--   <Country>#{record['shipping_address']['country']}</Country> -->
                  <!-- </ShipAddress> -->
                  #{record['line_items'].map { |l| sales_order_line_xml l }.join("")}
                </SalesOrderAdd>
              </SalesOrderAddRq>
            XML
          end

          def sales_order_line_xml(line)
            # <<-XML
            #     <SalesOrderLineAdd>
            #       <ItemRef>
            #         <!-- <ListID>IDTYPE</ListID> -->
            #         <FullName>#{line['product_id']}</FullName>
            #       </ItemRef>
            #       <Quantity>#{line['quantity']}</Quantity>
            #       <Amount>#{line['price']}</Amount>
            #       <!-- <Rate>PRICETYPE</Rate> -->
            #       <!-- <SalesTaxCodeRef> -->
            #       <!--   <ListID>IDTYPE</ListID> -->
            #       <!--   <FullName>STRTYPE</FullName> -->
            #       <!-- </SalesTaxCodeRef> -->
            #     </SalesOrderLineAdd>
            # XML
            ''
          end
      end
    end
  end
end
