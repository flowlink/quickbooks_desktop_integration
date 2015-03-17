module QBWC
  module Request
    class Shipments
      class << self
        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << search_xml(object['order_id'], session_id)
          end
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Object.new(config, {}).save_session(object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                       end
          end
        end


        def search_xml(shipment_id, session_id)
          <<-XML
  <InvoiceQueryRq requestID="#{session_id}">
    <RefNumberCaseSensitive>#{shipment_id}</RefNumberCaseSensitive>
    <IncludeLineItems>true</IncludeLineItems>
  </InvoiceQueryRq>
          XML
        end

        def update_xml_to_send(record, params = {}, session_id = nil)
          <<-XML
            <InvoiceModRq requestID="#{session_id}">
              <InvoiceMod>
                <TxnID>#{record['list_id']}</TxnID>
                <EditSequence>#{record['edit_sequence']}</EditSequence>
                #{invoice_xml(record, params)}
                #{items(record).map { |i| invoice_line_mod i }.join("")}
                #{adjustments(record).map { |i| invoice_adjustment_mod(i, params) }.join("")}
              </InvoiceMod>
            </InvoiceModRq>
          XML
        end

        def add_xml_to_send(record, params = {}, session_id = nil)
          <<-XML
            <InvoiceAddRq requestID="#{session_id}">
              <InvoiceAdd>
                #{invoice_xml(record, params)}
                #{items(record).map { |i| invoice_line_add i }.join("")}
                #{adjustments(record).map { |i| invoice_adjustment_add i }.join("")}
              </InvoiceAdd>
            </InvoiceAddRq>
          XML
        end

        def invoice_xml(record, params)
          <<-XML
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
          XML
        end

        def invoice_line_add(item)
          <<-XML
            <InvoiceLineAdd>
              #{quantity(item)}
              <Rate>#{item['price']}</Rate>
              #{link_to_sales_order(item)}
            </InvoiceLineAdd>
          XML
        end

        def invoice_line_mod(item)
          <<-XML
            <InvoiceLineMod>
              <TxnLineID>#{item['txn_line_id']}</TxnLineID>
              <ItemRef>
                <FullName>#{item['product_id']}</FullName>
              </ItemRef>
              #{quantity(item)}
              <Rate>#{item['price']}</Rate>
            </InvoiceLineMod>
          XML
        end

        def quantity(line)
          return '' if line['quantity'].to_f == 0.0

          "<Quantity>#{line['quantity']}</Quantity>"
        end

        def invoice_adjustment_add(item)
          <<-XML
            <InvoiceLineAdd>
              <Rate>#{item['value']}</Rate>
              #{link_to_sales_order(item)}
            </InvoiceLineAdd>
          XML
        end

        def invoice_adjustment_mod(item, params)
          <<-XML
            <InvoiceLineMod>
              <TxnLineID>#{item['txn_line_id']}</TxnLineID>
              <ItemRef>
                <FullName>#{QBWC::Request::Adjustments.adjustment_product_from_qb(item['name'].downcase, params)}</FullName>
              </ItemRef>
              <Rate>#{item['value']}</Rate>
            </InvoiceLineMod>
          XML
        end

        def link_to_sales_order(item)
          return '' unless item.has_key?('sales_order_txn_line_id') && !item['sales_order_txn_line_id'].to_s.empty?

          <<-XML
          <LinkToTxn>
            <TxnID>#{item['sales_order_txn_id']}</TxnID>
            <TxnLineID>#{item['sales_order_txn_line_id']}</TxnLineID>
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

        def build_products_from_shipments(objects)
          objects.first['items'].reject { |line| line['quantity'].to_f == 0.0 }.map do |item|
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
            'shipment_id'      => object['order_id'],
            'order_id'         => object['order_id'],
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

        def build_payment_from_shipments(object)
          {
            'id'               => object['order_id'],
            'order_id'         => object['order_id'],
          }
        end

        private

        def items(record)
          record['items'].to_a.sort{ |a,b| a['product_id'] <=> b['product_id'] }
        end

        def adjustments(record)
          record['adjustments'].to_a.reject{ |adj| adj['value'].to_f == 0.0 }.sort{ |a,b| a['name'].downcase <=> b['name'].downcase }
        end

        def build_adjustments(object)
          ['discount', 'tax', 'shipping'].select{ |name| object['totals'].has_key?(name) && object['totals'][name].to_f != 0.0 }.map do |adj_name|
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
