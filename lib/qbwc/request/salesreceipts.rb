# frozen_string_literal: true

module QBWC
  module Request
    class Salesreceipts

      MAPPING_ONE = [
        {qbe_name: "CustomerRef", flowlink_name: "customer_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "TemplateRef", flowlink_name: "template_name", is_ref: true},
        {qbe_name: "TxnDate", flowlink_name: "placed_on", is_ref: false},
        {qbe_name: "RefNumber", flowlink_name: "id", is_ref: false}
      ]

      MAPPING_TWO = [
        {qbe_name: "IsPending", flowlink_name: "is_pending", is_ref: false},
        {qbe_name: "CheckNumber", flowlink_name: "check_number", is_ref: false},
        {qbe_name: "PaymentMethodRef", flowlink_name: "payment_method_name", is_ref: true},
        {qbe_name: "DueDate", flowlink_name: "due_date", is_ref: false},
        {qbe_name: "SalesRepRef", flowlink_name: "sales_rep_name", is_ref: true},
        {qbe_name: "ShipDate", flowlink_name: "ship_date", is_ref: false},
        {qbe_name: "ShipMethodRef", flowlink_name: "shipping_method_name", is_ref: true},
        {qbe_name: "FOB", flowlink_name: "fob", is_ref: false},
        {qbe_name: "ItemSalesTaxRef", flowlink_name: "item_sales_tax_name", is_ref: true},
        {qbe_name: "Memo", flowlink_name: "memo", is_ref: false},
        {qbe_name: "CustomerMsgRef", flowlink_name: "customer_message_name", is_ref: true},
        {qbe_name: "IsToBePrinted", flowlink_name: "is_to_be_printed", is_ref: false},
        {qbe_name: "IsToBeEmailed", flowlink_name: "is_to_be_emailed", is_ref: false},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "CustomerSalesTaxCodeRef", flowlink_name: "customer_sales_tax_code_name", is_ref: true},
        {qbe_name: "DepositToAccountRef", flowlink_name: "deposit_to_account_name", is_ref: true},
        {qbe_name: "Other", flowlink_name: "other", is_ref: false},
        {qbe_name: "ExchangeRate", flowlink_name: "exchange_rate", is_ref: false},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}
      ]
      
      ADDRESS_MAP = [
        {qbe_name: "Addr1", flowlink_name: "address1", is_ref: false},
        {qbe_name: "Addr2", flowlink_name: "address2", is_ref: false},
        {qbe_name: "Addr3", flowlink_name: "address3", is_ref: false},
        {qbe_name: "Addr4", flowlink_name: "address4", is_ref: false},
        {qbe_name: "Addr5", flowlink_name: "address5", is_ref: false},
        {qbe_name: "City", flowlink_name: "city", is_ref: false},
        {qbe_name: "State", flowlink_name: "state", is_ref: false},
        {qbe_name: "PostalCode", flowlink_name: "zipcode", is_ref: false},
        {qbe_name: "Country", flowlink_name: "country", is_ref: false},
        {qbe_name: "Note", flowlink_name: "note", is_ref: false}
      ]
      
      # TODO: Map line items to a mapping here - lots of parsing for adjustments however...

      class << self
        def generate_request_queries(objects, params)
          puts "Generating request queries for objects: #{objects}, params: #{params}"
          objects.inject('') do |request, object|
            sanitize_sales_receipt(object)

            # Needed to keep shipment ID b/c and SalesReceipt already has a sales_receipt_id
            extra = "shipment-#{object['sales_receipt_id']}-" if object.key?('shipment_id')
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object, extra)

            new_string = request.dup
            new_string << search_xml(object['id'], session_id)
            request = new_string
          end
        end

        def generate_request_insert_update(objects, params = {})
          puts({connection: params[:connection_id], method: "generate_request_insert_update", message: "Generating insert/update", objects: objects, params: params})

          objects.inject('') do |request, object|
            puts({connection: params[:connection_id], method: "generate_request_insert_update", object: object, request: request})
            sanitize_sales_receipt(object)
            puts({connection: params[:connection_id], method: "generate_request_insert_update", object: object, message: "After sanitize"})
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            new_string = request.dup
            new_string << if object[:list_id].to_s.empty?
                            add_xml_to_send(object, params, session_id)
                          else
                            update_xml_to_send(object, params, session_id)
                          end
            puts({connection: params[:connection_id], method: "generate_request_insert_update", request: request, object: object})
            request = new_string
          end
        rescue Exception => e
          puts({connection: params[:connection_id], method: "generate_request_insert_update", message: "Exception", exception_message: e.message})
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
            <!-- polling sales_receipts -->
            <SalesReceiptQueryRq requestID="#{session_id}">
            <MaxReturned>100</MaxReturned>
              <ModifiedDateRangeFilter>
                <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </SalesReceiptQueryRq>
          XML
        end

        def search_xml(sales_receipt_id, session_id)
          <<~XML
            <SalesReceiptQueryRq requestID="#{session_id}">
              <RefNumberCaseSensitive>#{sales_receipt_id}</RefNumberCaseSensitive>
              <IncludeLineItems>true</IncludeLineItems>
            </SalesReceiptQueryRq>
          XML
        end

        def add_xml_to_send(record, params = {}, session_id)
          <<~XML
            <SalesReceiptAddRq requestID="#{session_id}">
              <SalesReceiptAdd>
                #{sales_receipt_xml(record, params, false)}
              </SalesReceiptAdd>
            </SalesReceiptAddRq>
          XML
        end

        def update_xml_to_send(record, params = {}, session_id)
          <<~XML
            <SalesReceiptModRq requestID="#{session_id}">
              <SalesReceiptMod>
                <TxnID>#{record['list_id']}</TxnID>
                <EditSequence>#{record['edit_sequence']}</EditSequence>
                #{sales_receipt_xml(record, params, true)}
              </SalesReceiptMod>
            </SalesReceiptModRq>
          XML
        end

        # NOTE Brave soul needed to find a lib or build one from scratch to
        # map this xml mess to proper ruby objects with a to_xml method

        # The sales_receipt of tags here matter. e.g. PONumber MUST be after
        # ship address or you end up getting:
        #
        #   QuickBooks found an error when parsing the provided XML text stream.
        #
        # View sales_receipt_add_rq.xml in case you need to look into add more
        # tags to this request
        #
        # View sales_receipt_add_rs_invalid_record_ref.xml to see what'd you
        # get by sending a invalid Customer Ref you'd get as a response.
        #
        # 'placed_on' needs to be a valid date string otherwise an exception
        # will be raised
        #
        def sales_receipt_xml(initial_object, config, is_mod)
          object = pre_mapping_logic(initial_object)

          if is_mod
            line_xml = items(object).map { |line| sales_receipt_line_mod(line) }.join('')
            adj_line_xml = adjustments_mod_xml(object, config)
          else
            line_xml = items(object).map { |line|
              if line[:is_bom]
                sales_receipt_group_line_add(line)
              else
                sales_receipt_line_add(line)
              end
            }.join('')
            adj_line_xml = adjustments_add_xml(object, config)
          end
          
          <<~XML
            #{add_fields(object, MAPPING_ONE, config, is_mod)}
            <BillAddress>
              #{add_fields(object['billing_address'], ADDRESS_MAP, config, is_mod) if object['billing_address']}
            </BillAddress>
            <ShipAddress>
              #{add_fields(object['shipping_address'], ADDRESS_MAP, config, is_mod) if object['shipping_address']}
            </ShipAddress>
            #{add_fields(object, MAPPING_TWO, config, is_mod)}
            #{line_xml}
            #{adj_line_xml}
          XML
        end

        def pre_mapping_logic(initial_object)
          object = initial_object

          object['placed_on'] = parse_string_to_date(object['placed_on'])

          # We determine refs in different ways in the code.
          # Setting up the object correctly here to use other ways of setting up refs
          unless object['customer_name']
            object['customer_name'] = object['customer']['name'] if object['customer']
          end
          unless object['sales_rep_name']
            object['sales_rep_name'] = object['sales_rep']['name'] if object['sales_rep']
          end
          unless object['shipping_method_name']
            object['shipping_method_name'] = object['shipping_method']['name'] if object['shipping_method']
          end
          unless object['payment_method_name']
            object['payment_method_name'] = object['payment_method']['name'] if object['payment_method']
          end

          object
        end

        def sales_receipt_line_add(line)
          <<~XML
            <SalesReceiptLineAdd>
              #{sales_receipt_line(line)}
            </SalesReceiptLineAdd>
          XML
        end

        def sales_receipt_group_line_add(line)
          <<~XML
            <SalesReceiptLineGroupAdd>
              #{sales_receipt_group_line(line)}
            </SalesReceiptLineGroupAdd>
          XML
        end

        def sales_receipt_line_add_optional_rate(line)
          line['price'].nil? ? rate = '' : rate = "<Rate>#{'%.2f' % line['price'].to_f}</Rate>"

          <<~XML
            <SalesReceiptLineAdd>
            <ItemRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemRef>
            <Desc>#{line['name']}</Desc>
            #{quantity(line)}
            #{rate}
            #{tax_code_line(line)}
            #{inventory_site(line)}
            #{amount_line(line)}
            </SalesReceiptLineAdd>
          XML
        end

        def sales_receipt_line_add_from_adjustment(adjustment, params)
          puts "IN sales sales_receipt PARAMS = #{params}"

          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name']) ? -1 : 1
          p_id = QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params, adjustment)
          puts "FOUND product_id #{p_id}, NAME #{adjustment['name']}"
          line = {
            'product_id' => p_id,
            'quantity' => 0,
            'price' => (adjustment['value'].to_f * multiplier).to_s
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']
          line['class_name'] = adjustment['class_name'] if adjustment['class_name']
          line['name'] = adjustment['description'] if adjustment['description']
          line['amount'] = adjustment['amount'] if adjustment['amount']

          line['use_amount'] = true if params['use_amount_for_tax'].to_s == "1"

          sales_receipt_line_add line
        end

        def sales_receipt_line_add_from_tax_line_item(tax_line_item, params)
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, tax_line_item),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'amount' => tax_line_item['amount'],
            'name' => tax_line_item['name']
          }

          sales_receipt_line_add_optional_rate line
        end

        def sales_receipt_line_mod(line)
          <<~XML
            <SalesReceiptLineMod>
              <TxnLineID>#{line['txn_line_id'] || -1}</TxnLineID>
              #{sales_receipt_line(line)}
            </SalesReceiptLineMod>
          XML
        end

        def sales_receipt_line_mod_from_adjustment(adjustment, params)
          
          multiplier = QBWC::Request::Adjustments.is_adjustment_discount?(adjustment['name']) ? -1 : 1
          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb(adjustment['name'], params),
            'quantity' => 0,
            'price' => (adjustment['value'].to_f * multiplier).to_s,
            'txn_line_id' => adjustment['txn_line_id']
          }

          line['tax_code_id'] = adjustment['tax_code_id'] if adjustment['tax_code_id']
          line['class_name'] = adjustment['class_name'] if adjustment['class_name']
          line['name'] = adjustment['description'] if adjustment['description']
          line['amount'] = adjustment['amount'] if adjustment['amount']

          line['use_amount'] = true if params['use_amount_for_tax'].to_s == "1"

          sales_receipt_line_mod line
        end

        def sales_receipt_line_mod_from_tax_line_item(tax_line_item, params)


          line = {
            'product_id' => QBWC::Request::Adjustments.adjustment_product_from_qb('tax', params, tax_line_item),
            'quantity' => 0,
            'price' => tax_line_item['value'],
            'amount' => tax_line_item['amount'],
            'name' => tax_line_item['name'],
            'txn_line_id' => tax_line_item['txn_line_id']
          }

          sales_receipt_line_mod line
        end

        def sales_receipt_line(line)
          <<~XML
            <ItemRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemRef>
            <Desc>#{line['name']}</Desc>
            #{quantity(line)}
            #{rate(line)}
            #{class_ref_for_receipt_line(line)}
            #{amount_line(line)}
            #{inventory_site(line)}
            #{tax_code_line(line)}
          XML
        end

        def sales_receipt_group_line(line)
          <<~XML
            <ItemGroupRef>
              <FullName>#{line['product_id']}</FullName>
            </ItemGroupRef>
            #{quantity(line)}
            #{rate(line)}
            #{class_ref_for_receipt_line(line)}
            #{amount_line(line)}
            #{inventory_site(line)}
            #{tax_code_line(line)}
          XML
        end

        def rate(line)
          return '' if !line['amount'].to_s.empty? || line['use_amount'] == true
          return '' unless price(line)

          <<~XML
            <Rate>#{'%.2f' % price(line).to_f}</Rate>
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

        def class_ref_for_receipt_line(line)
          return '' unless line['class_name']

          <<~XML
            <ClassRef>
              <FullName>#{line['class_name']}</FullName>
            </ClassRef>
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

        def rate_line(line)
          return '' if !line['amount'].to_s.empty? || line['use_amount'] == true

          <<~XML
            <Rate>#{'%.2f' % price(line).to_f}</Rate>
          XML
        end

        def quantity(line)
          return '' if line['quantity'].to_f == 0.0

          "<Quantity>#{line['quantity']}</Quantity>"
        end

        def tax_code_line(line)
          return '' if line['tax_code_id'].to_s.empty?
          if line['tax_list_id']
            list_id = "<ListID>#{line['tax_list_id']}</ListID>"
          else
            list_id = ''
          end

          <<~XML
            <SalesTaxCodeRef>
              #{list_id}
              <FullName>#{line['tax_code_id']}</FullName>
            </SalesTaxCodeRef>
          XML
        end

        def build_customer_from_sales_receipt(object)
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

        def build_products_from_sales_receipt(object)
          object.first['line_items'].reject { |line| line['quantity'].to_f == 0.0 }.map do |item|
            {
              'id'          => item['product_id'],
              'description' => item['description'],
              'price'       => item['price'],
              'cost_price'  => item['price']
            }
          end
        end

        def build_payments_from_sales_receipt(object)
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
              final_adjustments << sales_receipt_line_add_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << sales_receipt_line_add_from_tax_line_item(tax_line_item, params)
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
              final_adjustments << sales_receipt_line_mod_from_adjustment(adjustment, params)
            end
          end

          if use_tax_line_items
            record['tax_line_items'].each do |tax_line_item|
              final_adjustments << sales_receipt_line_mod_from_tax_line_item(tax_line_item, params)
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

        def sanitize_sales_receipt(sales_receipt)
          %w[billing_address shipping_address].each do |address_type|
            sales_receipt[address_type] = {} if sales_receipt[address_type].nil?

            %w[address1 address2 city state zipcode county].each do |field|
              sales_receipt[address_type][field]&.gsub!(/[^0-9A-Za-z\s]/, '')
            end
          end
        end

        def add_fields(object, mapping, config, is_mod)
          object = object.with_indifferent_access
          fields = ""
          mapping.each do |map_item|
            next if map_item[:mod_only] && map_item[:mod_only] != is_mod
            next if map_item[:add_only] && map_item[:add_only] == is_mod

            if map_item[:is_ref]
              fields += add_ref_xml(object, map_item, config)
            else
              fields += add_basic_xml(object, map_item)
            end
          end

          fields
        end

        def add_basic_xml(object, mapping)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]
          float_fields = ['price', 'cost']

          return '' if flowlink_field.nil? || flowlink_field == ""

          flowlink_field = '%.2f' % flowlink_field.to_f if float_fields.include?(mapping[:flowlink_name])

          "<#{qbe_field_name}>#{flowlink_field}</#{qbe_field_name}>"
        end

        def add_ref_xml(object, mapping, config)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]

          if flowlink_field.respond_to?(:has_key?) && flowlink_field['list_id']
            return "<#{qbe_field_name}><ListID>#{flowlink_field['list_id']}</ListID></#{qbe_field_name}>"
          end
          full_name = flowlink_field ||
                                config[mapping[:flowlink_name].to_sym] ||
                                config["quickbooks_#{mapping[:flowlink_name]}".to_sym]

          return '' if full_name.nil? || full_name == ""
          "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end

        def parse_string_to_date(str)
          return Time.now.to_date if str.nil? || str.empty?

          begin
            return Date.strptime(str, "%m-%d-%Y")
          rescue => exception
            begin
              return DateTime.parse(str).to_date
            rescue => exception
              return str
            end
          end
        end
      end
    end
  end
end
