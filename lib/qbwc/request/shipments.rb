module QBWC
  module Request
    class Shipments
      class << self
        def generate_request_queries(objects, params)
          ""
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Object.new(config, {}).save_session(object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                      else
                        ""
                      end
          end
        end

        def add_xml_to_send(record, params = {}, session_id = nil)
          <<-XML
            <InvoiceAddRq requestID="#{session_id}">
              <InvoiceAdd>
                <CustomerRef>
                  <FullName>#{record['email']}</FullName>
                </CustomerRef>
                <!-- <TxnDate>DATETYPE</TxnDate> -->
                <RefNumber>#{record['order_id']}</RefNumber>
                <!-- <IsFinanceCharge>BOOLTYPE</IsFinanceCharge> -->
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
                <IsPending>false</IsPending>
                <PONumber>#{record['id']}</PONumber>
                <!--
                <ShipMethodRef>
                  <FullName></FullName>
                </ShipMethodRef>
                -->
                #{record['items'].to_a.map { |i| invoice_line_add i }.join("")}
                #{record['adjustments'].to_a.select{ |adj| adj['value'].to_f > 0.0 }.map { |i| invoice_adjustment_add i }.join("")}
              </InvoiceAdd>
            </InvoiceAddRq>
          XML
        end

        def invoice_line_add(item)
          <<-XML
            <InvoiceLineAdd>
              <Quantity>#{item['quantity']}</Quantity>
              <Rate>#{item['price']}</Rate>
              #{link_to_sales_order(item)}
            </InvoiceLineAdd>
          XML
        end

        def invoice_adjustment_add(item)
          <<-XML
            <InvoiceLineAdd>
              <Quantity>1</Quantity>
              <Rate>#{item['value']}</Rate>
              #{link_to_sales_order(item)}
            </InvoiceLineAdd>
          XML
        end

        def link_to_sales_order(item)
          return '' unless item.has_key?('txn_id')

          <<-XML
          <LinkToTxn>
            <TxnID>#{item['txn_id']}</TxnID>
            <TxnLineID>#{item['txn_line_id']}</TxnLineID>
          </LinkToTxn>
          XML
        end

        def build_customer_from_shipments(object)
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

        def build_products_from_shipments(object)
          object.first['items'].map do |item|
            {
              'id'          => item['product_id'],
              'description' => item['name'],
              'price'       => item['price'],
              'cost_price'  => item['price']
            }
          end
        end

        def build_order_from_shipments(object)
          {
            'id'               => object['order_id'],
            'placed_on'        => (object.has_key?('placed_on') ? object['placed_on'] : object['shipped_at']),
            'shipment_id'      => object['id'],
            'firstname'        => object['billing_address']['firstname'],
            'lastname'         => object['billing_address']['lastname'],
            'email'            => object['email'],
            'billing_address'  => object['billing_address'],
            'shipping_address' => object['shipping_address'],
            'totals'           => object['totals'],
            'line_items'       => object['items'],
            'adjustments'      => build_adjustments(object)
          }
        end

        private
        def build_adjustments(object)
          ['discount', 'tax', 'shipping'].select{ |name| object['totals'][name].to_f > 0.0 }.map do |adj_name|
            {
              'name'  => adj_name,
              'value' => object['totals'][adj_name]
            }
          end
        end
      end
    end
  end
end
