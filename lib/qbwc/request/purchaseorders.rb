module QBWC
  module Request
    class Purchaseorders
      class << self
        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            sanitize_purchaseorder(object)

            # Needed to keep shipment ID b/c and Order already has a order_id
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object, extra)

            request << search_xml(object['id'], session_id)
          end
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_purchaseorder(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def search_xml(order_id, session_id)
          <<-XML
<PurchaseOrderQueryRq requestID="#{session_id}">
  <RefNumberCaseSensitive>#{order_id}</RefNumberCaseSensitive>
  <IncludeLineItems>true</IncludeLineItems>
</PurchaseOrderQueryRq>
          XML
        end

        def add_xml_to_send(record, params= {}, session_id)
          <<-XML

<PurchaseOrderAddRq requestID="#{session_id}">
  <PurchaseOrderAdd>
    #{purchaseorder record, params}
    #{items(record).map { |l| purchaseorder_line_add l }.join('')}
    #{adjustments_add_xml record, params}
  </PurchaseOrderAdd>
</PurchaseOrderAddRq>
          XML
        end

        def update_xml_to_send(record, params= {}, session_id)
          <<-XML

<PurchaseOrderModRq requestID="#{session_id}">
  <PurchaseOrderMod>
    <TxnID>#{record['list_id']}</TxnID>
    <EditSequence>#{record['edit_sequence']}</EditSequence>
    #{purchaseorder record, params}
    #{items(record).map { |l| purchaseorder_line_mod l }.join('')}
    #{adjustments_mod_xml record, params}
  </PurchaseOrderMod>
</PurchaseOrderModRq>
          XML
        end

        # NOTE Brave soul needed to find a lib or build one from scratch to
        # map this xml mess to proper ruby objects with a to_xml method

        # The order of tags here matter. e.g. PONumber MUST be after
        # ship address or you end up getting:
        #
        #   QuickBooks found an error when parsing the provided XML text stream.
        #
        # View purchaseorder_add_rq.xml in case you need to look into add more
        # tags to this request
        #
        # View purchaseorder_add_rs_invalid_record_ref.xml to see what'd you
        # get by sending a invalid Customer Ref you'd get as a response.
        #
        # 'placed_on' needs to be a valid date string otherwise an exception
        # will be raised
        #
        def purchaseorder(record, _params)
          if record['placed_on'].nil? || record['placed_on'].empty?
            record['placed_on'] = Time.now.to_s
          end

          <<-XML

    <VendorRef>
      <FullName>#{record['supplier']['name']}</FullName>
    </VendorRef>
    #{class_ref_for_order(record)}
    <TxnDate>#{Time.parse(record['placed_on']).to_date}</TxnDate>
    <RefNumber>#{record['id']}</RefNumber>
    <VendorAdress>
      <Addr1>#{record['billing_address']['address1']}</Addr1>
      <Addr2>#{record['billing_address']['address2']}</Addr2>
      <City>#{record['billing_address']['city']}</City>
      <State>#{record['billing_address']['state']}</State>
      <PostalCode>#{record['billing_address']['zipcode']}</PostalCode>
      <Country>#{record['billing_address']['country']}</Country>
    </VendorAdress>
    <ShipAddress>
      <Addr1>#{record['shipping_address']['address1']}</Addr1>
      <Addr2>#{record['shipping_address']['address2']}</Addr2>
      <City>#{record['shipping_address']['city']}</City>
      <State>#{record['shipping_address']['state']}</State>
      <PostalCode>#{record['shipping_address']['zipcode']}</PostalCode>
      <Country>#{record['shipping_address']['country']}</Country>
    </ShipAddress>
    #{cancel_order?(record)}
          XML
        end

        def class_ref_for_order(record)
          return '' unless record['class_name']

          <<-XML

    <ClassRef>
      <FullName>#{record['class_name']}</FullName>
    </ClassRef>
          XML
        end

        def class_ref_for_order_line(line)
          return '' unless line['class_name']

          <<-XML

      <ClassRef>
        <FullName>#{line['class_name']}</FullName>
      </ClassRef>
          XML
        end

        def purchaseorder_line_add(line)
          <<-XML

    <PurchaseOrderLineAdd>
      #{purchaseorder_line(line)}
    </PurchaseOrderLineAdd>
          XML
        end

        def purchaseorder_line_add_from_adjustment(adjustment, params)
          puts "IN purchase order PARAMS = #{params}"

          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name'])  ? -1 : 1
          p_id = QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params)
          puts "FOUND product_id #{p_id}, NAME #{adjustment['name']}"
          line = {
            'product_id' => p_id,
            'quantity' => 0,
            'price' => (adjustment['value'].to_f * multiplier).to_s
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']

          purchaseorder_line_add line
        end

        def purchaseorder_line_add_from_tax_line_item(tax_line_item, params)
          line = {
              'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params),
              'quantity' => 0,
              'price' => tax_line_item['value'],
              'name' => tax_line_item['name']
          }

          purchaseorder_line_add line
        end

        def purchaseorder_line_mod(line)
          <<-XML

    <PurchaseOrderLineMod>
      <TxnLineID>#{line['txn_line_id']}</TxnLineID>
      #{purchaseorder_line(line)}
    </PurchaseOrderLineMod>
          XML
        end

        def purchaseorder_line_mod_from_adjustment(adjustment, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params),
            'quantity' => 0,
            'price' => adjustment['value'],
            'txn_line_id' => adjustment['txn_line_id']
          }

          purchaseorder_line_mod line
        end

        def purchaseorder_line_mod_from_tax_line_item(tax_line_item, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'txn_line_id' => tax_line_item['txn_line_id'],
            'name' => tax_line_item['name']
          }

          purchaseorder_line_mod line
        end

        def purchaseorder_line(line)
          <<-XML

      <ItemRef>
        <FullName>#{line['product_id']}</FullName>
      </ItemRef>
      <Desc>#{line['name']}</Desc>
      #{quantity(line)}
      <Rate>#{'%.2f' % line['price'].to_f}</Rate>
      #{tax_code_line(line)}
          XML
        end

        def quantity(line)
          return '' if line['quantity'].to_f == 0.0

          "<Quantity>#{line['quantity']}</Quantity>"
        end

        def tax_code_line(line)
          return '' if line['tax_code_id'].to_s.empty?

          <<-XML

      <SalesTaxCodeRef>
        <FullName>#{line['tax_code_id']}</FullName>
      </SalesTaxCodeRef>
          XML
        end

        def cancel_order?(object)
          return '' unless object['status'].to_s == 'cancelled'

          <<-XML

          <IsManuallyClosed>true</IsManuallyClosed>

          XML
        end

        def build_vendor_from_purchaseorder(object)
          supplier_address = object['supplier_address']

          {
            'id'               => object['email'],
            'firstname'        => supplier_address['firstname'],
            'lastname'         => supplier_address['lastname'],
            'name'             => object['supplier']['name'],
            'company'          => supplier_address['company'],
            'email'            => object['email'],
            'supplier_address'  => supplier_address,
            'shipping_address' => object['shipping_address']
          }
        end

        def build_products_from_order(object)
          object.first['line_items'].reject { |line| line['quantity'].to_f == 0.0 }.map do |item|
            {
              'id'          => item['product_id'],
              'description' => item['description'],
              'price'       => item['price'],
              'cost_price'  => item['price']
            }
          end
        end

        def build_payments_from_order(object)
          object['payments'].to_a.select { |pay| %w(completed paid ready).include?(pay['status']) && pay['amount'].to_f > 0.0 }.map do |item|
            item.merge('id'          => object['id'],
                       'object_ref'  => object['id'],
                       'email'       => object['email'])
          end
        end

        private

        def items(record)
          record['line_items'].to_a.sort { |a, b| a['product_id'] <=> b['product_id'] }
        end

        # Generate XML for adding adjustments.
        # If the quickbooks_use_tax_line_items is set, then don't include tax from the adjustments object, and instead
        # use tax_line_items if it exists.
        def adjustments_add_xml(record, params)
        puts "record is #{record}"
          final_adjustments = []
          use_tax_line_items = !params['quickbooks_use_tax_line_items'].nil? &&
                                params['quickbooks_use_tax_line_items'] == "1" &&
                               !record['tax_line_items'].nil? &&
                               !record['tax_line_items'].empty?

          adjustments(record).each do |adjustment|
                      puts "adjustment is #{adjustment}"

            if !use_tax_line_items ||
               !QBWC::Request::Adjustments.is_adjustment_tax?(adjustment['name'])
              final_adjustments << purchaseorder_line_add_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << purchaseorder_line_add_from_tax_line_item(tax_line_item, params)
            end
          end

          final_adjustments.join('')
        end

        # Generate XML for modifying adjustments.
        # If the quickbooks_use_tax_line_items is set, then don't include tax from the adjustments object, and instead
        # use tax_line_items if it exists.
        def adjustments_mod_xml(record, params)
          final_adjustments = []
          use_tax_line_items = !params['quickbooks_use_tax_line_items'].nil? &&
              params['quickbooks_use_tax_line_items'] == "1" &&
              !record['tax_line_items'].nil? &&
              !record['tax_line_items'].empty?

          adjustments(record).each do |adjustment|
            if !use_tax_line_items ||
                !QBWC::Request::Adjustments.is_adjustment_tax?(adjustment['name'])
              final_adjustments << purchaseorder_line_mod_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << purchaseorder_line_mod_from_tax_line_item(tax_line_item, params)
            end
          end

          final_adjustments.join('')
        end

        def adjustments(record)
          record['adjustments']
            .to_a
            .reject { |adj| adj['value'].to_f == 0.0 }
            .sort { |a, b| a['name'].downcase <=> b['name'].downcase }
        end

        def sanitize_purchaseorder(order)
          ['billing_address', 'shipping_address'].each do |address_type|
            if order[address_type].nil?
              order[address_type] = { }
            end

            ['address1', 'address2', 'city', 'state', 'zipcode', 'county'].each do |field|
              if !order[address_type][field].nil?
                order[address_type][field].gsub!(/[^0-9A-Za-z\s]/, '')
              end
            end
          end
        end

      end
    end
  end
end
