module QBWC
  module Request
    class Orders
      class << self
        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            sanitize_order(object)

            # Needed to keep shipment ID b/c and Order already has a order_id
            extra = "shipment-#{object['order_id']}-" if object.key?('shipment_id')
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object, extra)

            request << search_xml(object['id'], session_id)
          end
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_order(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params['quickbooks_since']
          session_id = Persistence::Session.save(config, 'polling' => timestamp)
          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling orders -->
            <SalesOrderQueryRq requestID="#{session_id}">
            <MaxReturned>100</MaxReturned>
              <ModifiedDateRangeFilter>
                <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </SalesOrderQueryRq>
          XML
        end

        def search_xml(order_id, session_id)
          <<~XML
            <SalesOrderQueryRq requestID="#{session_id}">
              <RefNumberCaseSensitive>#{order_id}</RefNumberCaseSensitive>
              <IncludeLineItems>true</IncludeLineItems>
            </SalesOrderQueryRq>
          XML
        end

        def add_xml_to_send(record, params= {}, session_id)
          <<~XML
            <SalesOrderAddRq requestID="#{session_id}">
              <SalesOrderAdd>
                #{sales_order record, params}
                #{external_guid(record)}
                #{items(record).map { |l| sales_order_line_add l }.join('')}
                #{adjustments_add_xml record, params}
              </SalesOrderAdd>
            </SalesOrderAddRq>
          XML
        end

        def update_xml_to_send(record, params= {}, session_id)
          <<~XML
            <SalesOrderModRq requestID="#{session_id}">
              <SalesOrderMod>
                <TxnID>#{record['list_id']}</TxnID>
                <EditSequence>#{record['edit_sequence']}</EditSequence>
                #{sales_order record, params}
                #{items(record).map { |l| sales_order_line_mod l }.join('')}
                #{adjustments_mod_xml record, params}
              </SalesOrderMod>
            </SalesOrderModRq>
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
        # 'placed_on' needs to be a valid date string otherwise an exception
        # will be raised
        #
        def sales_order(record, _params)
          if record['placed_on'].nil? || record['placed_on'].empty?
            record['placed_on'] = Time.now.to_s
          end

          <<~XML
            #{customer_ref_for_order(record)}
            #{class_ref_for_order(record)}
            #{template_ref_for_order(record)}
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
            #{terms_ref_for_order(record)}
            #{ship_date(record)}
            #{cancel_order?(record)}
          XML
        end

        def external_guid(record)
          return '' unless record['external_guid']

          <<~XML
          <ExternalGUID>#{record['external_guid']}</ExternalGUID>
          XML
        end

        def customer_ref_for_order(record)
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

        def class_ref_for_order(record)
          return '' unless record['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{record['class_name']}</FullName>
            </ClassRef>
          XML
        end

        def template_ref_for_order(record)
          return '' unless record['template']

          <<~XML
            <TemplateRef>
              <FullName>#{record['template']}</FullName>
            </TemplateRef>
          XML
        end

        def terms_ref_for_order(record)
          return '' unless record['terms_name']

          <<~XML
            <TermsRef>
              <FullName>#{record['terms_name']}</FullName>
            </TermsRef>
          XML
        end

        def po_number(record)
          return '' unless record['purchase_order_number']

          <<~XML
            <PONumber>
              #{record['purchase_order_number']}
            </PONumber>
          XML
        end

        def ship_date(record)
          return '' unless record['ship_date']

          <<~XML
            <ShipDate>
              #{record['ship_date']}
            </ShipDate>
          XML
        end

        def class_ref_for_order_line(line)
          return '' unless line['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{line['class_name']}</FullName>
            </ClassRef>
          XML
        end

        def sales_order_line_add(line)
          <<~XML
            <SalesOrderLineAdd>
              #{sales_order_line(line)}
            </SalesOrderLineAdd>
          XML
        end

        def sales_order_line_add_from_adjustment(adjustment, params, record)
          puts "IN sales order PARAMS = #{params}"

          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name'])  ? -1 : 1
          p_id = QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params, record)
          puts "FOUND product_id #{p_id}, NAME #{adjustment['name']}"
          line = {
            'product_id' => p_id,
            'quantity' => 0,
            'price' => sprintf('%.2f', (adjustment['value'].to_f * multiplier))
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']
          line['amount'] = adjustment['amount'] if adjustment['amount']

          line['use_amount'] = true if params['use_amount_for_tax'].to_s == "1"

          sales_order_line_add line
        end

        def sales_order_line_add_from_tax_line_item(tax_line_item, params, record)
          line = {
              'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, record),
              'quantity' => 0,
              'price' => sprintf('%.2f', tax_line_item['value']),
              'name' => tax_line_item['name']
          }

          sales_order_line_add line
        end

        def sales_order_line_mod(line)
          <<~XML
            <SalesOrderLineMod>
              <TxnLineID>#{line['txn_line_id']}</TxnLineID>
              #{sales_order_line(line)}
            </SalesOrderLineMod>
          XML
        end

        def sales_order_line_mod_from_adjustment(adjustment, params, record)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params, record),
            'quantity' => 0,
            'price' => adjustment['value'],
            'txn_line_id' => adjustment['txn_line_id']
          }

          sales_order_line_mod line
        end

        def sales_order_line_mod_from_tax_line_item(tax_line_item, params, record)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, record),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'txn_line_id' => tax_line_item['txn_line_id'],
            'name' => tax_line_item['name']
          }

          sales_order_line_mod line
        end

        def sales_order_line(line)
          <<~XML
            <ItemRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemRef>
            <Desc>#{line['name']}</Desc>
            #{quantity(line)}
            #{rate_line(line)}
            #{amount_line(line)}
            #{tax_code_line(line)}
            #{amount_line(line)}
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
          return '' if !line['amount'].to_s.empty?

          <<~XML
            <Rate>#{'%.2f' % price(line).to_f}</Rate>
          XML
        end

        def amount_line(line)
          return '' if rate_line(line) != ''

          amount = line['amount'] || price(line)
          return '' unless amount

          <<~XML
            <Amount>#{'%.2f' % amount.to_f}</Amount>
          XML
        end

        def cancel_order?(object)
          return '' unless object['status'].to_s == 'cancelled' || object['status'].to_s == 'closed'

          <<~XML
            <IsManuallyClosed>true</IsManuallyClosed>
          XML
        end

        def build_customer_from_order(object)
          billing_address = object['billing_address']

          {
            'list_id'          => object['customer']['list_id'],
            'id'               => object['customer']['name'],
            'firstname'        => billing_address['firstname'],
            'lastname'         => billing_address['lastname'],
            'name'             => object['customer']['name'],
            'company'          => billing_address['company'],
            'email'            => object['email'],
            'billing_address'  => billing_address,
            'shipping_address' => object['shipping_address'],
            'request_id' => object['request_id']
          }.compact
        end

        def build_products_from_order(object)
          puts "Building products from #{object}"

          object.first['line_items'].reject { |line| line['quantity'].to_f == 0.0 }.map do |item|
            {
              'id'          => item['product_id'],
              'product_id'  => item['product_id'],
              'description' => item['description'],
              'price'       => item['price'],
              'cost'  => item['cost'],
              'income_account' => item['income_account'],
              'inventory_account' => item['inventory_account'],
              'cogs_account' => item['cogs_account'],
              'unit_of_measure' => item['unit_of_measure']

            }
          end
        end

        def build_payments_from_order(object)
          object['payments'].to_a.map do |payment|
            {
              id: payment['id'],
              customer: object['customer'],
              invoice_txn_id: object['transaction_id'],
              amount: payment['amount'],
              payment_method: payment['payment_method'],
              deposit_account: payment['deposit_account'],
              credit_amount: payment['credit_amount'],
              credit_txn_id: payment['credit_txn_id']
            }
          end
        end

        private

        def price(line)
          line['line_item_price'] || line['price']
        end

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
              final_adjustments << sales_order_line_add_from_adjustment(adjustment, params, record)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << sales_order_line_add_from_tax_line_item(tax_line_item, params, record)
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
              final_adjustments << sales_order_line_mod_from_adjustment(adjustment, params, record)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << sales_order_line_mod_from_tax_line_item(tax_line_item, params, record)
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

        def sanitize_order(order)
          ['billing_address', 'shipping_address'].each do |address_type|
            if order[address_type].nil?
              order[address_type] = { }
            end

            ['address1', 'address2', 'city', 'state', 'zipcode', 'country'].each do |field|
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
