module QBWC
  module Request
    class Customers

      FIELD_MAP = {
        IsActive: "is_active",
        CompanyName: "company",
        Salutation: "salutation",
        MiddleName: "middlename",
        JobTitle: "job_title",
        Fax: "fax",
        Cc: "cc",
        Contact: "contact",
        AltContact: "alternative_contact",
        ResaleNumber: "resale_number",
        AccountNumber: "account_number",
        CreditLimit: "credit_limit",
        JobStartDate: "job_start_date",
        JobProjectedEndDate: "job_projected_end_date",
        JobEndDate: "job_end_date",
        JobDesc: "job_description",
        Notes: "notes",
        ExternalGUID: "external_guid",
        TaxRegistrationNumber: "tax_registration_number",
        OpenBalance: "open_balance",
        OpenBalanceDate: "open_balance_date"
      }

      ADDRESS_MAP = {
        Addr1: "address1",
        Addr2: "address2",
        Addr3: "address3",
        Addr4: "address4",
        Addr5: "address5",
        City: "city",
        State: "state",
        PostalCode: "zipcode",
        Country: "country",
        Note: "note"
      }

      REF_MAP = {
        ClassRef: "class_name",
        ParentRef: "parent_name",
        CustomerTypeRef: "customer_type_name",
        TermsRef: "terms",
        SalesRepRef: "sales_rep_name",
        SalesTaxCodeRef: "sales_tax_code_name",
        ItemSalesTaxRef: "item_sales_tax_name",
        PreferredPaymentMethodRef: "preferred_payment_method_name",
        JobTypeRef: "job_type_name",
        PriceLevelRef: "price_level_name",
        CurrencyRef: "currency_name"
      }

      CONTACTS_MAP = {
        Salutation: "salutation",
        FirstName: "firstname",
        MiddleName: "middlename",
        LastName: "lastname",
        JobTitle: "job_title"
      }

      SALES_TAX_COUNTRIES = ['Australia', 'Canada', 'UK', 'US']
      JOB_STATUSES = ['Awarded', 'Closed', 'InProgress', 'None', 'NotAwarded', 'Pending']
      DELIVERY_METHODS = ['None', 'Email', 'Fax']

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << (object[:list_id].to_s.empty? ? add_xml_to_send(object, session_id) : update_xml_to_send(object, session_id))
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
            <!-- polling customers -->
            <CustomerQueryRq requestID="#{session_id}">
              <MaxReturned>100000</MaxReturned>
              #{query_by_date(params, time)}
            </CustomerQueryRq>
          XML
        end

        def query_by_date(config, time)
          puts "Customer config for polling: #{config}"
          return '' if config['return_all']

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            puts "Customer object: #{object}"
            puts "Customer object list id: #{object['list_id']}"

            if object['list_id'].to_s.empty?
              request << search_xml_by_name(object['name'], session_id)
            else
              request << search_xml_by_id(object['list_id'], session_id)
            end


          end
        end

        def search_xml_by_id(object_id, session_id)
          puts "Building customer xml by list_id #{object_id}, #{session_id}"

          <<~XML
            <CustomerQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              <ListIDList>
                #{object_id}
              </ListIDList>
            </CustomerQueryRq>
          XML
        end

        def search_xml_by_name(object_id, session_id)
          puts "Building customer xml by name #{object_id}, #{session_id}"

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

        def add_xml_to_send(object, session_id)
          <<~XML
            <CustomerAddRq requestID="#{session_id}">
              <CustomerAdd>
                <Name>#{object['name']}</Name>
                <FirstName>#{object['firstname'] ? object['name'].split.first : object['firstname']}</FirstName>
                #{"<LastName>#{object['lastname'] || object['name'].split.last}</LastName>" if object['lastname']}
                <Phone>#{object['billing_address']['phone'] if object['billing_address']}</Phone>
                <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
                <Email>#{object['email']}</Email>
                #{add_fields(object, FIELD_MAP)}
                #{add_refs(object)}
                #{sales_tax_country(object)}
                #{job_status(object)}
                #{preferred_delivery_method(object)}
                <BillAddress>
                  #{add_fields(object['billing_address'], ADDRESS_MAP) if object['billing_address']}
                </BillAddress>
                <ShipAddress>
                  #{add_fields(object['shipping_address'], ADDRESS_MAP) if object['shipping_address']}
                </ShipAddress>
                #{ship_to_address(object)}
                #{additional_contacts(object)}
                #{additional_notes(object)}
                #{contacts(object)}
              </CustomerAdd>
            </CustomerAddRq>
          XML
        end

        def update_xml_to_send(object, session_id)
          <<~XML
            <CustomerModRq requestID="#{session_id}">
              <CustomerMod>
                <ListID>#{object['list_id']}</ListID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                <Name>#{object['name']}</Name>
                <FirstName>#{object['firstname'] ? object['name'].split.first : object['firstname']}</FirstName>
                #{"<LastName>#{object['lastname'] || object['name'].split.last}</LastName>" if object['lastname']}
                <Phone>#{object['billing_address']['phone'] if object['billing_address']}</Phone>
                <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
                <Email>#{object['email']}</Email>
                #{add_fields(object, FIELD_MAP)}
                #{add_refs(object)}
                #{sales_tax_country(object)}
                #{job_status(object)}
                #{preferred_delivery_method(object)}
                <BillAddress>
                  #{add_fields(object['billing_address'], ADDRESS_MAP) if object['billing_address']}
                </BillAddress>
                <ShipAddress>
                  #{add_fields(object['shipping_address'], ADDRESS_MAP) if object['shipping_address']}
                </ShipAddress>
                #{ship_to_address(object)}
                #{additional_contacts(object)}
                #{additional_notes(object)}
                #{contacts(object)}
              </CustomerMod>
            </CustomerModRq>
          XML
        end

        private

        def ship_to_address(object)
          return "" unless object['ship_to_address'] && object['ship_to_address'].is_a?(Array)

          fields = ""
          object['ship_to_address'].each do |addr|
            fields += "<ShipToAddress>"
            fields += "<Name>#{addr['name']}</Name>"
            fields += "<DefaultShipTo>#{addr['default_ship_to']}</DefaultShipTo>"
            fields += add_fields(addr, ADDRESS_MAP)
            fields += "</ShipToAddress>"
          end
          
          fields
        end

        def add_refs(object)
          fields = ""
          REF_MAP.each do |qbe_name, flowlink_name|
            full_name = object[flowlink_name] || config[flowlink_name]
            fields += "<#{qbe_name}><FullName>#{full_name}</FullName></#{qbe_name}>" unless full_name.nil?
          end

          fields
        end

        def add_fields(object, mapping)
          fields = ""
          mapping.each do |qbe_name, flowlink_name|
            fields += "<#{qbe_name}>#{object[flowlink_name]}</#{qbe_name}>\n" unless object[flowlink_name].nil?
          end

          fields
        end

        def sales_tax_country(object)
          return "" unless SALES_TAX_COUNTRIES.include?(object['sales_tax_country'])
          "<SalesTaxCountry>#{object['sales_tax_country']}</SalesTaxCountry>"
        end

        def job_status(object)
          return "" unless JOB_STATUSES.include?(object['job_status'])
          "<JobStatus>#{object['job_status']}</JobStatus>"
        end

        def preferred_delivery_method(object)
          return "" unless DELIVERY_METHODS.include?(object['preferred_delivery_method'])
          "<PreferredDeliveryMethod>#{object['preferred_delivery_method']}</PreferredDeliveryMethod>"
        end

        def additional_contacts(object)
          return unless object['additional_contacts'] && object['additional_contacts'].is_a?(Array)
          
          fields = ""
          object['additional_contacts'].each do |contact|
            # Both name and value required
            next unless contact['name'] && contact['value']
            fields += <<~XML
                              <AdditionalContactRef>
                                <ContactName >#{contact['name']}</ContactName>
                                <ContactValue >#{contact['value']}</ContactValue>
                              </AdditionalContactRef>
                            XML
          end

          fields
        end

        def additional_notes(object)
          return unless object['additional_notes'] && object['additional_notes'].is_a?(Array)
          
          fields = ""
          object['additional_notes'].each do |note|
            fields += "<AdditionalNotes><Note>#{note}</Note></AdditionalNotes>"
          end

          fields
        end

        def contacts(object)
          return unless object['contacts'] && object['contacts'].is_a?(Array)
          
          fields = ""
          object['contacts'].each do |contact|
            fields += "<Contacts>"
            fields += add_fields(contact, CONTACTS_MAP)
            fields += additional_contacts(contact)
            fields += "</Contacts>"
          end

          fields
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
