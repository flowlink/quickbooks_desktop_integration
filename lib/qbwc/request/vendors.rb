module QBWC
  module Request
    class Vendors

      FIELD_MAP = {
        IsActive: "is_active",
        Salutation: "salutation",
        MiddleName: "middlename",
        JobTitle: "job_title",
        Fax: "fax",
        Cc: "cc",
        Contact: "contact",
        AltContact: "alternative_contact",
        CreditLimit: "credit_limit",
        VendorTaxIdent: "vendor_tax_ident",
        IsVendorEligibleFor1099: "is_vendor_eligible_for_1099",
        OpenBalance: "open_balance",
        OpenBalanceDate: "open_balance_date",
        ExternalGUID: "external_guid",
        NameOnCheck: "name_on_check",
        AccountNumber: "account_number",
        Notes: "notes",
        IsSalesTaxAgency: "is_sales_tax_agency",
        TaxRegistrationNumber: "tax_registration_number",
        IsTaxTrackedOnPurchases: "is_tax_tracked_on_purchases",
        IsTaxTrackedOnSales: "is_tax_tracked_on_sales",
        IsTaxOnTax: "is_tax_on_tax",
        CompanyName: "company"
      }

      REF_MAP = {
        ClassRef: "class_name",
        BillingRateRef: "billing_rate_name",
        VendorTypeRef: "vendor_type_name",
        TermsRef: "terms",
        SalesTaxCodeRef: "sales_tax_code_name",
        SalesTaxReturnRef: "sales_tax_return_name",
        TaxOnPurchasesAccountRef: "tax_on_purchases_account_name",
        TaxOnSalesAccountRef: "tax_on_sales_account_name",
        CurrencyRef: "currency_name"
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

      CONTACTS_MAP = {
        Salutation: "salutation",
        FirstName: "firstname",
        MiddleName: "middlename",
        LastName: "lastname",
        JobTitle: "job_title"
      }

      SALES_TAX_COUNTRIES = ['Australia', 'Canada', 'UK', 'US']
      REPORTING_PERIODS = ['Monthly', 'Quarterly']

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_vendor(object)

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

          <<-XML
            <!-- polling customers -->
            <VendorQueryRq requestID="#{session_id}">
              <MaxReturned>100000</MaxReturned>
              #{query_by_date(params, time)}
            </VendorQueryRq>
          XML
        end

        def query_by_date(config, time)
          puts "Vendor config for polling: #{config}"
          return '' if config['return_all']

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end

        def generate_request_queries(objects, params)
          puts "Vendor request query for #{objects}, #{params}"

          objects.inject('') do |request, object|
            puts "Inject process #{request}, #{object}"
            sanitize_vendor(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object['id'], session_id)
          end
        end

        def search_xml(object_id, session_id)
          <<-XML
            <VendorQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              <NameRangeFilter>
                <FromName>#{object_id}</FromName>
                <ToName>#{object_id}</ToName>
              </NameRangeFilter>
            </VendorQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id)
          <<-XML
            <VendorAddRq requestID="#{session_id}">
              <VendorAdd>
                <Name>#{object['name']}</Name>
                <FirstName>#{object['firstname'] || object['name'].split.first}</FirstName>
                #{"<LastName>#{object['lastname'] || object['name'].split.last}</LastName>" if object['lastname']}
                <Phone>#{object['vendor_address']['phone'] if object['vendor_address']}</Phone>
                <AltPhone>#{object['ship_from_address']['phone'] if object['ship_from_address']}</AltPhone>
                <Email>#{object['email']}</Email>
                #{add_fields(object, FIELD_MAP)}
                #{sales_tax_country(object)}
                #{reporting_period(object)}
                #{add_refs(object)}
                <VendorAddress>
                  #{add_fields(object['vendor_address'], ADDRESS_MAP) if object['vendor_address']}
                </VendorAddress>
                <ShipAddress>
                  #{add_fields(object['ship_from_address'], ADDRESS_MAP) if object['ship_from_address']}
                </ShipAddress>
                #{additional_contacts(object)}
                #{additional_notes(object)}
                #{contacts(object)}
              </VendorAdd>
            </VendorAddRq>
          XML
        end

        def update_xml_to_send(object, session_id)
          <<-XML
            <VendorModRq requestID="#{session_id}">
              <VendorMod>
                <ListID>#{object['list_id']}</ListID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                <Name>#{object['name']}</Name>
                <FirstName>#{object['firstname']}</FirstName>
                <LastName>#{object['lastname']}</LastName>
                <Phone>#{object['vendor_address']['phone'] if object['vendor_address']}</Phone>
                <AltPhone>#{object['ship_from_address']['phone'] if object['ship_from_address']}</AltPhone>
                <Email>#{object['email']}</Email>
                #{add_fields(object, FIELD_MAP)}
                #{sales_tax_country(object)}
                #{reporting_period(object)}
                #{add_refs(object)}
                <VendorAddress>
                  #{add_fields(object['vendor_address'], ADDRESS_MAP) if object['vendor_address']}
                </VendorAddress>
                <ShipAddress>
                  #{add_fields(object['ship_from_address'], ADDRESS_MAP) if object['ship_from_address']}
                </ShipAddress>
                #{additional_contacts(object)}
                #{additional_notes(object)}
                #{contacts(object)}
              </VendorMod>
            </VendorModRq>
          XML
        end

        private

        def add_refs(object)
          fields = ""
          REF_MAP.each do |qbe_name, flowlink_name|
            fields += "<#{qbe_name}><FullName>#{object[flowlink_name]}</FullName></#{qbe_name}>" unless object[flowlink_name].nil?
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

        def reporting_period(object)
          return "" unless REPORTING_PERIODS.include?(object['reporting_period'])
          "<ReportingPeriod>#{object['reporting_period']}</ReportingPeriod>"
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

        def sanitize_vendor(vendor)
          puts "Sanitizing: #{vendor}"
          # vendor['company'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['company']
          vendor['firstname'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['firstname']
          # vendor['name'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['name']
          vendor['lastname'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['lastname']
          # vendor['email'] = nil unless vendor['email'] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

          vendor['vendor_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['address1']
          vendor['vendor_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['address2']
          vendor['vendor_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['city']
          vendor['vendor_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['state']
          vendor['vendor_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['zipcode']
          vendor['vendor_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['country']
          vendor['vendor_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['vendor_address'] && vendor['vendor_address']['phone']
          vendor['ship_from_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['address1']
          vendor['ship_from_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['address2']
          vendor['ship_from_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['city']
          vendor['ship_from_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['state']
          vendor['ship_from_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['zipcode']
          vendor['ship_from_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['phone']
          vendor['ship_from_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if vendor['ship_from_address'] && vendor['ship_from_address']['country']
        end
      end
    end
  end
end

# TODO: Still need these on Add/Update (not sure what they do)
# <PrefillAccountRef> <!-- must occur 0 - 3 times -->
#         <ListID >IDTYPE</ListID> <!-- optional -->
#         <FullName >STRTYPE</FullName> <!-- optional -->
# </PrefillAccountRef>
