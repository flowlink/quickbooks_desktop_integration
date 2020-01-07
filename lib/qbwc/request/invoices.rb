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

            new_string = request.dup
            new_string << search_xml(object['id'], session_id)
            request = new_string
          end
        end

        def generate_request_insert_update(objects, params = {})
          puts "Generating insert/update for objects: #{objects}, params: #{params}"
          objects.inject('') do |request, object|
            sanitize_invoice(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            new_string = request.dup
            new_string << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)

                       else
                         update_xml_to_send(object, params, session_id)
                      end
            request = new_string
          end
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params
          timestamp = params['quickbooks_since'] if params['return_all']

          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling invoices -->
            <InvoiceQueryRq requestID="#{session_id}">
              <MaxReturned>300</MaxReturned>
              #{query_by_date(params, time)}
              <IncludeLineItems>true</IncludeLineItems>
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </InvoiceQueryRq>
          XML
        end

        def query_by_date(config, time)
          puts "Invoices config for polling: #{config}"
          return query_by_txn_date(config, time) if config['return_all']

          <<~XML
            <ModifiedDateRangeFilter>
              <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
            </ModifiedDateRangeFilter>
          XML
        end

        def query_by_txn_date(config, time)
          <<~XML
            <TxnDateRangeFilter>
              <FromTxnDate>#{time.to_date.iso8601}</FromTxnDate>
            </TxnDateRangeFilter>
          XML
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

        # The invoice of tags here matter. e.g. PONumber MUST be after
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

          <<~XML
            #{customer_ref_for_invoice(record)}
            #{class_ref_for_invoice(record)}
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
            #{po_number(record)}
            #{sales_rep(record)}
            #{shipping_method(record)}
            #{is_to_be_printed(record)}
            #{is_to_be_emailed(record)}
          XML
        end

        def shipping_method(record)
          return '' unless record.dig('shipping_method','name')

          <<~XML
            <ShipMethodRef>
              <FullName>#{record['shipping_method']['name']}</FullName>
            </ShipMethodRef>
          XML
        end

        def is_to_be_printed(record)
          return '' unless record.dig('is_to_be_printed')

          <<~XML
            <IsToBePrinted>#{record['is_to_be_printed']}</IsToBePrinted>
          XML
        end

        def is_to_be_emailed(record)
          return '' unless record.dig('is_to_be_emailed')

          <<~XML
            <IsToBeEmailed>#{record['is_to_be_emailed']}</IsToBeEmailed>
          XML
        end

        def sales_rep(record)
          return '' unless record.dig('sales_rep','name')

          <<~XML
            <SalesRepRef>
              <FullName>#{record['sales_rep']['name']}</FullName>
            </SalesRepRef>
          XML
        end

        def po_number(record)
          return '' unless record['purchase_order_number'] && record['purchase_order_number'] != ""

          <<~XML
            <PONumber>#{record['purchase_order_number']}</PONumber>
          XML
        end

        def customer_ref_for_invoice(record)
          return customer_by_id(record) if record['customer']['list_id']

          <<~XML
            <CustomerRef>
              <FullName>#{record['customer']['name']}</FullName>
            </CustomerRef>
          XML
        end

        def customer_by_id(record)
          <<~XML
            <CustomerRef>
              <ListID>#{record['customer']['list_id']}</ListID>
            </CustomerRef>
          XML
        end

        def class_ref_for_invoice(record)
          return '' unless record['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{record['class_name']}</FullName>
            </ClassRef>
          XML
        end

        def class_ref_for_invoice_line(line)
          return '' unless line['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{line['class_name']}</FullName>
            </ClassRef>
          XML
        end

        def invoice_line_add(line)
          <<~XML
            <InvoiceLineAdd>
              #{invoice_line(line)}
            </InvoiceLineAdd>
          XML
        end

        def invoice_line_add_from_adjustment(adjustment, params, record)
          puts "IN sales invoice PARAMS = #{params}"

          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name']) ? -1 : 1
          p_id = QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params, record)
          puts "FOUND product_id #{p_id}, NAME #{adjustment['name']}, multiplier: #{multiplier}, #{adjustment['value'].to_f * multiplier}"
          line = {
            'product_id' => p_id,
            'quantity' => 0,
            'price' => (adjustment['value'].to_f * multiplier).to_s
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']
          line['amount'] = adjustment['amount'] if adjustment['amount']

          line['use_amount'] = true if params['use_amount_for_tax'].to_s == "1"
          puts params['connection_id']
          puts "Adding Tax... Should we use amount? #{params['use_amount_for_tax']} - so line is now: #{line}" if params['connection_id'] == "oilsolutionsgroup"


          invoice_line_add line
        end

        def invoice_line_add_from_tax_line_item(tax_line_item, params, record)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, record),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'name' => tax_line_item['name']
          }

          invoice_line_add line
        end

        def invoice_line_mod(line)
          <<~XML
            <InvoiceLineMod>
              <TxnLineID>#{line['txn_line_id']}</TxnLineID>
              #{invoice_line(line)}
            </InvoiceLineMod>
          XML
        end

        def invoice_line_mod_from_adjustment(adjustment, params, record)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params, record),
            'quantity' => 0,
            'price' => adjustment['value'],
            'txn_line_id' => adjustment['txn_line_id']
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']
          line['amount'] = adjustment['amount'] if adjustment['amount']

          invoice_line_mod line
        end

        def invoice_line_mod_from_tax_line_item(tax_line_item, params, record)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, record),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'txn_line_id' => tax_line_item['txn_line_id'],
            'name' => tax_line_item['name']
          }

          invoice_line_mod line
        end

        def invoice_line(line)
          <<~XML
            <ItemRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemRef>
            <Desc>#{line['name']}</Desc>
            #{quantity(line)}
            #{rate_line(line)}
            #{amount_line(line)}
            #{tax_code_line(line)}
            #{inventory_site(line)}
          XML
        end

        def inventory_site(line)
          return '' unless line['inventory_site_name']

          <<~XML
            <InventorySiteRef>
              <FullName>#{line['inventory_site_name']}</FullName>
            </InventorySiteRef>
          XML
        end

        def quantity(line)
          return '' if line['quantity'].to_f == 0.0

          "<Quantity>#{line['quantity']}</Quantity>"
        end

        def tax_code_line(line)
          return '' if line['tax_code_id'].to_s.empty?

          <<~XML
            <SalesTaxCodeRef>
              <FullName>#{line['tax_code_id']}</FullName>
            </SalesTaxCodeRef>
          XML
        end

        def rate_line(line)
          return '' if !line['amount'].to_s.empty? || line['use_amount'] == true

          <<~XML
            <Rate>#{'%.2f' % price(line).to_f}</Rate>
          XML
        end

        def amount_line(line)
          return '' if line['amount'].to_s.empty?
          return '' if rate_line(line) != ''

          amount = line['amount'] || price(line)

          <<~XML
            <Amount>#{'%.2f' % amount.to_f}</Amount>
          XML
        end


        def build_customer_from_invoice(object)
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

        def build_products_from_invoice(object)
          object.first['line_items'].reject { |line| line['quantity'].to_f == 0.0 }.map do |item|
            {
              'id'          => item['product_id'],
              'description' => item['description'],
              'price'       => item['price'],
              'cost_price'  => item['price']
            }
          end
        end

        def build_payments_from_invoice(object)
          object['payments'].to_a.select { |pay| %w[completed paid ready].include?(pay['status']) && pay['amount'].to_f > 0.0 }.map do |item|
            item.merge('id'          => object['id'],
                       'object_ref'  => object['id'],
                       'email'       => object['email'])
          end
        end

        private

        def price(line)
          line['line_item_price'] || line['price']
        end

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
              final_adjustments << invoice_line_add_from_adjustment(adjustment, params, record)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << invoice_line_add_from_tax_line_item(tax_line_item, params, record)
            end
          end

          puts "Final adjustments #{final_adjustments.join('')}"
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
              final_adjustments << invoice_line_mod_from_adjustment(adjustment, params, record)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << invoice_line_mod_from_tax_line_item(tax_line_item, params, record)
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

        def sanitize_invoice(invoice)
          %w[billing_address shipping_address].each do |address_type|
            invoice[address_type] = {} if invoice[address_type].nil?

            %w[address1 address2 city state zipcode county].each do |field|
              invoice[address_type][field]&.gsub!(/[^0-9A-Za-z\s]/, '')
            end
          end
        end
      end
    end
  end
end
