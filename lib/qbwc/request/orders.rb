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
            if txn_id = object['quickbooks_txn_id']
              request << search_xml(txn_id)
            else
              request
            end
          end
        end

        # We could assume all references presented in the order exists
        # in quickbooks if any of them dont, grab the error on the response
        # and persist the missing reference. QBWC scheduler should keep
        # running until all references are there and the sales order can
        # finally be persisted.
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
          def search_xml(txn_id)
           <<-XML
            <SalesOrderQueryRq>
              <TxnID>#{txn_id}</TxnID>
              <!-- <RefNumberCaseSensitive>STRTYPE</RefNumberCaseSensitive> -->
              <!-- <MaxReturned>INTTYPE</MaxReturned> -->
              <!-- <OwnerID>GUIDTYPE</OwnerID> -->
            </SalesOrderQueryRq>
            XML
          end

          def add_xml_to_send(record, params= {})
            <<-XML
<SalesOrderAddRq>
  <SalesOrderAdd>
    #{sales_order record, params}
  </SalesOrderAdd>
</SalesOrderAddRq>
<SalesOrderAddRq>
  <SalesOrderAdd>
    <!-- test multiple order one valid one invalid -->
    <CustomerRef>
      <FullName>nononononoImNotThereAlrightDylan</FullName>
    </CustomerRef>
    <SalesOrderLineAdd>
      <ItemRef>
        <FullName>totally wrong product id</FullName>
      </ItemRef>
      <Quantity>1</Quantity>
      <Rate>10</Rate>
    </SalesOrderLineAdd>
  </SalesOrderAdd>
</SalesOrderAddRq>
            XML
          end

          # NOTE Brave soul needed to find a lib or build one from scratch to
          # map this xml mess to proper ruby objects with a to_xml method

          # The order of tags here matter. e.g. PONumber MUST be after
          # ship address or you end up getting:
          #   
          #   QuickBooks found an error when parsing the provided XML text stream.
          # 
          # View sales_order_add_rq.xml in case you need to look into add more
          # tags to this request
          #
          # View sales_order_add_rs_invalid_record_ref.xml to see what'd you
          # get by sending a invalid Customer Ref you'd get as a response.
          #   
          def sales_order(record, params)
            <<-XML
    <CustomerRef>
      <!--
      <ListID>80000009-1415929219</ListID>
      Instead of ListId we can pass fullname instead which maps to Wombat
      customer_id -->
      <FullName>a123191</FullName>
    </CustomerRef>
    <!--
    R154085346875 is a too long value for this according to quickbooks
    so lets use PONumber to map Wombat orders id instead. Quickbooks
    will increment this value each time a sales order is added
    -->
    <!-- <RefNumber></RefNumber> -->
    <!-- likely exception spot here 'placed_on' needs to be a valid date string -->
    <TxnDate>#{Time.parse(record['placed_on']).to_date}</TxnDate>
    <BillAddress>
      <Addr1>#{record['billing_address']['address1']}</Addr1>
      <Addr2>#{record['billing_address']['address2']}</Addr2>
      <City>#{record['billing_address']['city']}</City>
      <State>#{record['billing_address']['state']}</State>
      <PostalCode>#{record['billing_address']['zipcode']}</PostalCode>
      <Country>#{record['billing_address']['country']}</Country>
    </BillAddress>
    <ShipAddress>
      <Addr1>#{record['shipping_address']['address1']}</Addr1>
      <Addr2>#{record['shipping_address']['address2']}</Addr2>
      <City>#{record['shipping_address']['city']}</City>
      <State>#{record['shipping_address']['state']}</State>
      <PostalCode>#{record['shipping_address']['zipcode']}</PostalCode>
      <Country>#{record['shipping_address']['country']}</Country>
    </ShipAddress>
    <PONumber>#{record['id']}</PONumber>
    #{record['line_items'].map { |l| sales_order_line_xml l }.join("")}
            XML
          end

          def sales_order_line_xml(line)
<<-XML
    <SalesOrderLineAdd>
      <ItemRef>
        <!-- <ListID>IDTYPE</ListID> -->
        <FullName>#{line['product_id']}</FullName>
      </ItemRef>
      <Quantity>#{line['quantity']}</Quantity>
      <!-- <Amount>#{'%.2f' % line['price'].to_f}</Amount> -->
      <Rate>#{line['price']}</Rate>
      <!-- <SalesTaxCodeRef> -->
      <!--   <ListID>IDTYPE</ListID> -->
      <!--   <FullName>STRTYPE</FullName> -->
      <!-- </SalesTaxCodeRef> -->
    </SalesOrderLineAdd>
XML
          end
      end
    end
  end
end
