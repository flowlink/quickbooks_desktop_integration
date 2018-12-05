# frozen_string_literal: true

module QBWC
  module Request
    class Invoices
      class << self
        def generate_request_queries(objects, params)
          puts "Generating request queries for objects: #{objects}, params: #{params}"
          objects.inject('') do |request, object|
            sanitize_invoice(object)

            # Needed to keep shipment ID b/c and Invoice already has a invoice_id
            extra = "shipment-#{object['invoice_id']}-" if object.key?('shipment_id')
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object, extra)

            request << search_xml(object['id'], session_id)
          end
        end 

        def generate_request_insert_update(objects, params = {})
          puts "Generating insert/update for objects: #{objects}, params: #{params}"
          objects.inject('') do |request, object|
            sanitize_invoice(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def search_xml(invoice_id, session_id)
          <<~XML
<InvoiceQueryRq requestID="#{session_id}">
  <RefNumberCaseSensitive>#{invoice_id}</RefNumberCaseSensitive>
  <IncludeLineItems>true</IncludeLineItems>
</InvoiceQueryRq>
          XML
        end

        def add_xml_to_send(record, params = {}, session_id)
          <<~XML

<InvoiceAddRq requestID="#{session_id}">
  <InvoiceAdd>
    #{invoice record, params}
    #{items(record).map { |l| invoice_line_add l }.join('')}
    #{adjustments_add_xml record, params}
  </InvoiceAdd>
</InvoiceAddRq>
          XML
        end

        def update_xml_to_send(record, params = {}, session_id)
          <<~XML

<InvoiceModRq requestID="#{session_id}">
  <InvoiceMod>
    <TxnID>#{record['list_id']}</TxnID>
    <EditSequence>#{record['edit_sequence']}</EditSequence>
    #{invoice record, params}
    #{items(record).map { |l| invoice_line_mod l }.join('')}
    #{adjustments_mod_xml record, params}
  </InvoiceMod>
</InvoiceModRq>
          XML
        end

        # NOTE Brave soul needed to find a lib or build one from scratch to
        # map this xml mess to proper ruby objects with a to_xml method

        # The order of tags here matter. e.g. PONumber MUST be after
        # ship address or you end up getting:
        #
        #   QuickBooks found an error when parsing the provided XML text stream.
        #
        # View invoice_add_rq.xml in case you need to look into add more
        # tags to this request
        #
        # View invoice_add_rs_invalid_record_ref.xml to see what'd you
        # get by sending a invalid Customer Ref you'd get as a response.
        #
        # 'placed_on' needs to be a valid date string otherwise an exception
        # will be raised
        #
        def invoice(record, _params)
          puts "Building invoice XML for #{record}"
          if record['placed_on'].nil? || record['placed_on'].empty?
            record['placed_on'] = Time.now.to_s
          end

          <<-XML

    <CustomerRef>
      <FullName>#{record['customer']['name']}</FullName>
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
          XML
        end

        def invoice_line_add(line)
          <<-XML

    <InvoiceLineAdd>
      #{invoice_line(line)}
    </InvoiceLineAdd>
          XML
        end

        def invoice_line_add_from_adjustment(adjustment, params)
          puts "IN sales invoice PARAMS = #{params}"

          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name']) ? -1 : 1
          p_id = QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params)
          puts "FOUND product_id #{p_id}, NAME #{adjustment['name']}"
          line = {
            'product_id' => p_id,
            'quantity' => 0,
            'price' => (adjustment['value'].to_f * multiplier).to_s
          }

          invoice_line_add line
        end

        def invoice_line_add_from_tax_line_item(tax_line_item, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'name' => tax_line_item['name']
          }

          invoice_line_add line
        end

        def invoice_line_mod(line)
          <<-XML

    <InvoiceLineMod>
      <TxnLineID>#{line['txn_line_id']}</TxnLineID>
      #{invoice_line(line)}
    </InvoiceLineMod>
          XML
        end

        def invoice_line_mod_from_adjustment(adjustment, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params),
            'quantity' => 0,
            'price' => adjustment['value'],
            'txn_line_id' => adjustment['txn_line_id']
          }

          invoice_line_mod line
        end

        def invoice_line_mod_from_tax_line_item(tax_line_item, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'txn_line_id' => tax_line_item['txn_line_id'],
            'name' => tax_line_item['name']
          }

          invoice_line_mod line
        end

        def invoice_line(line)
          puts "Building invoice line XML..."
          @invoice_line_xml=<<-XML

      <ItemRef>
        <FullName>#{line['product_id']}</FullName>
      </ItemRef>
      <Desc>#{line['name']}</Desc>
      #{quantity(line)}
      <Rate>#{'%.2f' % line['price'].to_f}</Rate>
      #{tax_code_line(line)}
          XML
          puts @invoice_line_xml.gsub("\n", '')
          @invoice_line_xml
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

        def build_customer_from_order(object)
          billing_address = object['billing_address']

          {
            'id'               => object['email'],
            'firstname'        => billing_address['firstname'],
            'lastname'         => billing_address['lastname'],
            'name'             => billing_address['name'],
            'company'          => billing_address['company'],
            'email'            => object['email'],
            'billing_address'  => billing_address,
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
          object['payments'].to_a.select { |pay| %w[completed paid ready].include?(pay['status']) && pay['amount'].to_f > 0.0 }.map do |item|
            item.merge('id'          => object['id'],
                       'object_ref'  => object['id'],
                       'email'       => object['email'])
          end
        end

        private

        def items(record)
          record['line_items'].to_a.sort_by { |a| a['product_id'] }
        end

        # Generate XML for adding adjustments.
        # If the quickbooks_use_tax_line_items is set, then don't include tax from the adjustments object, and instead
        # use tax_line_items if it exists.
        def adjustments_add_xml(record, params)
          puts "record is #{record}"
          final_adjustments = []
          use_tax_line_items = !params['quickbooks_use_tax_line_items'].nil? &&
                               params['quickbooks_use_tax_line_items'] == '1' &&
                               !record['tax_line_items'].nil? &&
                               !record['tax_line_items'].empty?

          adjustments(record).each do |adjustment|
            puts "adjustment is #{adjustment}"

            if !use_tax_line_items ||
               !QBWC::Request::Adjustments.is_adjustment_tax?(adjustment['name'])
              final_adjustments << invoice_line_add_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << invoice_line_add_from_tax_line_item(tax_line_item, params)
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
                               params['quickbooks_use_tax_line_items'] == '1' &&
                               !record['tax_line_items'].nil? &&
                               !record['tax_line_items'].empty?

          adjustments(record).each do |adjustment|
            if !use_tax_line_items ||
               !QBWC::Request::Adjustments.is_adjustment_tax?(adjustment['name'])
              final_adjustments << invoice_line_mod_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << invoice_line_mod_from_tax_line_item(tax_line_item, params)
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

        def sanitize_invoice(order)
          %w[billing_address shipping_address].each do |address_type|
            order[address_type] = {} if order[address_type].nil?

            %w[address1 address2 city state zipcode county].each do |field|
              order[address_type][field]&.gsub!(/[^0-9A-Za-z\s]/, '')
            end
          end
        end
      end
    end
  end
end
