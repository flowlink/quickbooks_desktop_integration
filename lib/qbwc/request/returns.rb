module QBWC
  module Request
    class Returns
      class << self

        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']},{}).save_session(object)
            request << search_xml(object['id'], session_id)
          end
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']},{}).save_session(object)
            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                      else
                        update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def search_xml(return_id, session_id)
         <<-XML
          <SalesReceiptQueryRq requestID="#{session_id}">
            <RefNumberCaseSensitive>#{return_id}</RefNumberCaseSensitive>
          </SalesReceiptQueryRq>
          XML
        end

        def add_xml_to_send(record, params= {}, session_id)
          <<-XML
            <SalesReceiptAddRq requestID="#{session_id}">
              <SalesReceiptAdd>
                #{sales_receipt record, params}
                #{record['line_items'].map { |l| sales_receipt_line_add l }.join("")}
              </SalesReceiptAdd>
            </SalesReceiptAddRq>
          XML
        end

        def update_xml_to_send(record, params= {}, session_id)
          #{record['line_items'].map { |l| sales_receipt_line_mod l }.join("")}

          <<-XML
            <SalesReceiptModRq requestID="#{session_id}">
              <SalesReceiptMod>
                <TxnID>#{record['list_id']}</TxnID>
                <EditSequence>#{record['edit_sequence']}</EditSequence>
                #{sales_receipt record, params}
              </SalesReceiptMod>
            </SalesReceiptModRq>
          XML
        end

        def sales_receipt(record, params)
          <<-XML
            <CustomerRef>
              <FullName>#{record['email']}</FullName>
            </CustomerRef>
            <TxnDate>#{Time.parse(record['placed_on']).to_date}</TxnDate>
            <RefNumber>#{record['id']}</RefNumber>
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
            #{payment_ref(record, params)}
          XML
        end
        def payment_ref(record, params)
          # TODO test
          return ''
          <<-XML
            <PaymentMethodRef>
              <FullName></FullName>
            </PaymentMethodRef>
          XML
        end
        def sales_receipt_line_add(line)
          <<-XML
            <SalesReceiptLineAdd>
              #{sales_receipt_line(line)}
            </SalesReceiptLineAdd>
          XML
        end

        def sales_receipt_line_mod(line)
          <<-XML
            <SalesReceiptLineMod>
              #{sales_receipt_line(line)}
            </SalesReceiptLineMod>
          XML
        end

        def sales_receipt_line(line)
          <<-XML
              <ItemRef>
                <FullName>#{line['product_id']}</FullName>
              </ItemRef>
              <Quantity>#{line['quantity']}</Quantity>

              <!-- <Amount>#{'%.2f' % line['price'].to_f}</Amount> -->
              <Rate>#{line['price']}</Rate>

              <!-- might be needed same as tax_code_id in qb online -->
              <!-- <SalesTaxCodeRef> -->
              <!--   <ListID>IDTYPE</ListID> -->
              <!--   <FullName>STRTYPE</FullName> -->
              <!-- </SalesTaxCodeRef> -->
          XML
        end

        def build_customer_from_return(object)
          billing_address = object['billing_address']

          {
            'id'               => object['email'],
            'firstname'        => billing_address['firstname'],
            'lastname'         => billing_address['lastname'],
            'email'            => object['email'],
            'billing_address'  => billing_address,
            'shipping_address' => object['shipping_address']
          }
        end

        def build_products_from_return(object)
          object.first['items'].map do |item|
            {
              'id'          => item['product_id'],
              'description' => item['description'],
              'price'       => item['price'],
              'cost_price'  => item['price']
            }
          end
        end
      end
    end
  end
end
