module QBWC
  module Request
    class Customers

      MAPPING_ONE = [
        {qbe_name: "Name", flowlink_name: "name", is_ref: false},
        {qbe_name: "IsActive", flowlink_name: "is_active", is_ref: false},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "CompanyName", flowlink_name: "company", is_ref: false},
        {qbe_name: "Salutation", flowlink_name: "salutation", is_ref: false},
        {qbe_name: "FirstName", flowlink_name: "firstname", is_ref: false},
        {qbe_name: "MiddleName", flowlink_name: "middlename", is_ref: false},
        {qbe_name: "LastName", flowlink_name: "lastname", is_ref: false},
        {qbe_name: "JobTitle", flowlink_name: "job_title", is_ref: false}
      ]

      MAPPING_TWO = [
        {qbe_name: "Phone", flowlink_name: "phone", is_ref: false},
        {qbe_name: "AltPhone", flowlink_name: "mobile", is_ref: false},
        {qbe_name: "Fax", flowlink_name: "fax", is_ref: false},
        {qbe_name: "Email", flowlink_name: "email", is_ref: false},
        {qbe_name: "Cc", flowlink_name: "cc", is_ref: false},
        {qbe_name: "Contact", flowlink_name: "contact", is_ref: false},
        {qbe_name: "AltContact", flowlink_name: "alternative_contact", is_ref: false}
      ]

      MAPPING_THREE = [
        {qbe_name: "CustomerTypeRef", flowlink_name: "customer_type_name", is_ref: true},
        {qbe_name: "TermsRef", flowlink_name: "terms", is_ref: true},
        {qbe_name: "SalesRepRef", flowlink_name: "sales_rep_name", is_ref: true},
        {qbe_name: "OpenBalance", flowlink_name: "open_balance", is_ref: false, add_only: true},
        {qbe_name: "OpenBalanceDate", flowlink_name: "open_balance_date", is_ref: false, add_only: true},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "ItemSalesTaxRef", flowlink_name: "item_sales_tax_name", is_ref: true},
        {qbe_name: "SalesTaxCountry", flowlink_name: "sales_tax_country", is_ref: false},
        {qbe_name: "ResaleNumber", flowlink_name: "resale_number", is_ref: false},
        {qbe_name: "AccountNumber", flowlink_name: "account_number", is_ref: false},
        {qbe_name: "CreditLimit", flowlink_name: "credit_limit", is_ref: false},
        {qbe_name: "PreferredPaymentMethodRef", flowlink_name: "preferred_payment_method_name", is_ref: true},
        {qbe_name: "JobStatus", flowlink_name: "job_status", is_ref: false},
        {qbe_name: "JobStartDate", flowlink_name: "job_start_date", is_ref: false},
        {qbe_name: "JobProjectedEndDate", flowlink_name: "job_projected_end_date", is_ref: false},
        {qbe_name: "JobEndDate", flowlink_name: "job_end_date", is_ref: false},
        {qbe_name: "JobDesc", flowlink_name: "job_description", is_ref: false},
        {qbe_name: "JobTypeRef", flowlink_name: "job_type_name", is_ref: true},
        {qbe_name: "Notes", flowlink_name: "notes", is_ref: false}
      ]

      MAPPING_FOUR = [
        {qbe_name: "PreferredDeliveryMethod", flowlink_name: "preferred_delivery_method", is_ref: false},
        {qbe_name: "PriceLevelRef", flowlink_name: "price_level_name", is_ref: true},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true},
        {qbe_name: "TaxRegistrationNumber", flowlink_name: "tax_registration_number", is_ref: false},
        {qbe_name: "CurrencyRef", flowlink_name: "currency_name", is_ref: true}
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

      CONTACTS_MAP = [
        {qbe_name: "Salutation", flowlink_name: "salutation", is_ref: false},
        {qbe_name: "FirstName", flowlink_name: "firstname", is_ref: false},
        {qbe_name: "MiddleName", flowlink_name: "middlename", is_ref: false},
        {qbe_name: "LastName", flowlink_name: "lastname", is_ref: false},
        {qbe_name: "JobTitle", flowlink_name: "job_title", is_ref: false}
      ]

      SALES_TAX_COUNTRIES = ['Australia', 'Canada', 'UK', 'US']
      JOB_STATUSES = ['Awarded', 'Closed', 'InProgress', 'None', 'NotAwarded', 'Pending']
      DELIVERY_METHODS = ['None', 'Email', 'Fax']

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << (object[:list_id].to_s.empty? ? add_xml_to_send(object, session_id, config) : update_xml_to_send(object, session_id, config))
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
            <!-- polling customers -->
            <CustomerQueryRq requestID="#{session_id}">
              #{query_inactive?(params)}
              #{query_by_date(params, time)}
              <OwnerID>0</OwnerID>
            </CustomerQueryRq>
          XML
        end

        def query_by_date(config, time)
          return '' if config['return_all'].to_i == 1

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            if object['list_id'].to_s.empty?
              request << search_xml_by_name(object['name'], session_id)
            else
              request << search_xml_by_id(object['list_id'], session_id)
            end


          end
        end

        def search_xml_by_id(object_id, session_id)
          <<~XML
            <CustomerQueryRq requestID="#{session_id}">
              <ListID>#{object_id}</ListID>
            </CustomerQueryRq>
          XML
        end

        def search_xml_by_name(object_id, session_id)
          <<~XML
            <CustomerQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              <NameRangeFilter>
                <FromName>#{object_id}</FromName>
                <ToName>#{object_id}</ToName>
              </NameRangeFilter>
            </CustomerQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id, config)
          <<~XML
            <CustomerAddRq requestID="#{session_id}">
              <CustomerAdd>
                #{customer_xml(object, config, false)}
              </CustomerAdd>
            </CustomerAddRq>
          XML
        end

        def update_xml_to_send(object, session_id, config)
          <<~XML
            <CustomerModRq requestID="#{session_id}">
              <CustomerMod>
                <ListID>#{object['list_id']}</ListID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                #{customer_xml(object, config, true)}
              </CustomerMod>
            </CustomerModRq>
          XML
        end

        private

        def query_inactive?(config)
          return '' unless config['query_inactive'].to_i == 1

          <<~XML
            <ActiveStatus>All</ActiveStatus>
          XML
        end

        def customer_xml(initial_object, config, is_mod)
          object = pre_mapping_logic(initial_object)

          <<~XML
            #{add_fields(object, MAPPING_ONE, config, is_mod)}
            #{address(object['billing_address'], config, is_mod, "BillAddress")}
            #{address(object['shipping_address'], config, is_mod, "ShipAddress")}
            #{ship_to_address(object['ship_to_address'], config, is_mod)}
            #{add_fields(object, MAPPING_TWO, config, is_mod)}
            #{additional_contacts(object['additional_contacts'])}
            #{contacts(object['contacts'], config, is_mod)}
            #{add_fields(object, MAPPING_THREE, config, is_mod)}
            #{additional_notes(object['additional_notes'], is_mod)}
            #{add_fields(object, MAPPING_FOUR, config, is_mod)}
          XML
        end

        def address(addr, config, is_mod, address_name)
          return "" if addr.nil?
          return "<#{address_name} />" unless addr.is_a?(Hash) && !addr.empty?

          <<~XML
            <#{address_name}>
              #{add_fields(addr, ADDRESS_MAP, config, is_mod)}
            </#{address_name}>
          XML
        end

        def ship_to_address(ship_to, config, is_mod)
          return "" if ship_to.nil?
          return "<ShipToAddress />" unless ship_to.is_a?(Array) && !ship_to.empty?

          ship_to = ship_to[0...50] if ship_to.length > 50
          fields = ""
          ship_to.each do |addr|
            default_ship_to = addr['default_ship_to'] == true ? true : false

            fields += "<ShipToAddress>"
            fields += "<Name>#{addr['name']}</Name>" if addr['name']
            fields += add_fields(addr, ADDRESS_MAP, config, is_mod)
            fields += "<DefaultShipTo>#{default_ship_to}</DefaultShipTo>"
            fields += "</ShipToAddress>"
          end

          fields
        end

        def additional_contacts(contacts)
          return "" if contacts.nil?
          return "<AdditionalContactRef />" unless contacts.is_a?(Array) && !contacts.empty?

          fields = ""
          contacts.each do |contact|
            # Both name and value required
            next unless contact['name'] && contact['value']
              fields += "<AdditionalContactRef>"
              fields += "<ContactName >#{contact['name']}</ContactName>"
              fields += "<ContactValue >#{contact['value']}</ContactValue>"
              fields += "</AdditionalContactRef>"
          end

          fields
        end

        def additional_notes(notes, is_mod)
          return "" if notes.nil?
          return is_mod ? "<AdditionalNotesMod />" : "<AdditionalNotes />" unless notes.is_a?(Array) && !notes.empty?

          fields = ""
          notes.each do |note|
            next unless note && note['note']

            fields += is_mod ? "<AdditionalNotesMod>" : "<AdditionalNotes>"
            fields += "<NoteID>#{note['id']}</NoteID>" if is_mod
            fields += "<Note>#{note['note']}</Note>"
            fields += is_mod ? "</AdditionalNotesMod>" : "</AdditionalNotes>"
          end

          fields
        end

        def contacts(contacts, config, is_mod)
          return "" if contacts.nil?
          return is_mod ? "<ContactsMod />" : "<Contacts />" unless contacts.is_a?(Array) && !contacts.empty?

          fields = ""
          contacts.each do |contact|
            fields += is_mod ? "<ContactsMod>" : "<Contacts>"
            fields += add_fields(contact, CONTACTS_MAP, config, is_mod)
            fields += additional_contacts(contact['additional_contacts'])
            fields += is_mod ? "</ContactsMod>" : "</Contacts>"
          end

          fields
        end

        def pre_mapping_logic(initial_object)
          object = initial_object

          object['is_active'] = true unless object['is_active'] == false

          object['preferred_delivery_method'] = nil unless DELIVERY_METHODS.include?(object['preferred_delivery_method'])
          object['job_status'] = nil unless JOB_STATUSES.include?(object['job_status'])
          object['sales_tax_country'] = nil unless SALES_TAX_COUNTRIES.include?(object['sales_tax_country'])

          object
        end

        def add_fields(object, mapping, config, is_mod)
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

          return '' if flowlink_field.nil?

          if flowlink_field != "" && float_fields.include?(mapping[:flowlink_name])
            flowlink_field = '%.2f' % flowlink_field.to_f
          end

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

          return '' if full_name.nil?
          "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end

        def sanitize_customer(customer)
          # customer['company'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['company']
          customer['firstname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['firstname']
          # customer['name'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['name']
          customer['lastname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['lastname']
          # customer['email'] = nil unless customer['email'] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

          customer['billing_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['address1']
          customer['billing_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['address2']
          customer['billing_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['city']
          customer['billing_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['state']
          customer['billing_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['zipcode']
          customer['billing_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['country']
          customer['billing_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['phone']
          customer['shipping_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['address1']
          customer['shipping_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['address2']
          customer['shipping_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['city']
          customer['shipping_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['state']
          customer['shipping_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['zipcode']
          customer['shipping_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['phone']
          customer['shipping_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['country']
        end
      end
    end
  end
end
