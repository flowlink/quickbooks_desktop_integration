module QBWC
  module Request
    class Vendors

      MAPPING_ONE = [
        {qbe_name: "Name", flowlink_name: "name", is_ref: false},
        {qbe_name: "IsActive", flowlink_name: "is_active", is_ref: false},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
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
        {qbe_name: "NameOnCheck", flowlink_name: "name_on_check", is_ref: false},
        {qbe_name: "AccountNumber", flowlink_name: "account_number", is_ref: false},
        {qbe_name: "Notes", flowlink_name: "notes", is_ref: false}
      ]

      MAPPING_FOUR = [
        {qbe_name: "VendorTypeRef", flowlink_name: "vendor_type_name", is_ref: true},
        {qbe_name: "TermsRef", flowlink_name: "terms", is_ref: true},
        {qbe_name: "CreditLimit", flowlink_name: "credit_limit", is_ref: false},
        {qbe_name: "VendorTaxIdent", flowlink_name: "vendor_tax_ident", is_ref: false},
        {qbe_name: "IsVendorEligibleFor1099", flowlink_name: "is_vendor_eligible_for_1099", is_ref: false},
        {qbe_name: "OpenBalance", flowlink_name: "open_balance", is_ref: false, add_only: true},
        {qbe_name: "OpenBalanceDate", flowlink_name: "open_balance_date", is_ref: false, add_only: true},
        {qbe_name: "BillingRateRef", flowlink_name: "billing_rate_name", is_ref: true},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "SalesTaxCountry", flowlink_name: "sales_tax_country", is_ref: false},
        {qbe_name: "IsSalesTaxAgency", flowlink_name: "is_sales_tax_agency", is_ref: false},
        {qbe_name: "SalesTaxReturnRef", flowlink_name: "sales_tax_return_name", is_ref: true},
        {qbe_name: "TaxRegistrationNumber", flowlink_name: "tax_registration_number", is_ref: false},
        {qbe_name: "ReportingPeriod", flowlink_name: "reporting_period", is_ref: false},
        {qbe_name: "IsTaxTrackedOnPurchases", flowlink_name: "is_tax_tracked_on_purchases", is_ref: false},
        {qbe_name: "TaxOnPurchasesAccountRef", flowlink_name: "tax_on_purchases_account_name", is_ref: true},
        {qbe_name: "IsTaxTrackedOnSales", flowlink_name: "is_tax_tracked_on_sales", is_ref: false},
        {qbe_name: "TaxOnSalesAccountRef", flowlink_name: "tax_on_sales_account_name", is_ref: true},
        {qbe_name: "IsTaxOnTax", flowlink_name: "is_tax_on_tax", is_ref: false},
        {qbe_name: "CurrencyRef", flowlink_name: "currency_name", is_ref: true},
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
      REPORTING_PERIODS = ['Monthly', 'Quarterly']

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            puts "OSG!" if params['connection_id'] == 'oilsolutionsgroup'
            sanitize_vendor(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            if params['connection_id'] == 'oilsolutionsgroup'
              puts "OSG"
              puts add_xml_to_send(object, session_id, config)
            end

            request << (object[:list_id].to_s.empty? ? add_xml_to_send(object, session_id, config) : update_xml_to_send(object, session_id, config))
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
          <<~XML
            <VendorQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              <NameRangeFilter>
                <FromName>#{object_id}</FromName>
                <ToName>#{object_id}</ToName>
              </NameRangeFilter>
            </VendorQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id, config)
          <<~XML
            <VendorAddRq requestID="#{session_id}">
              <VendorAdd>
                #{vendor_xml(object, config, false)}
              </VendorAdd>
            </VendorAddRq>
          XML
        end

        def update_xml_to_send(object, session_id, config)
          <<~XML
            <VendorModRq requestID="#{session_id}">
              <VendorMod>
                <ListID>#{object['list_id']}</ListID>
                <EditSequence>#{object['edit_sequence']}</EditSequence>
                #{vendor_xml(object, config, true)}
              </VendorMod>
            </VendorModRq>
          XML
        end

        private

        def vendor_xml(initial_object, config, is_mod)
          object = pre_mapping_logic(initial_object)

          <<~XML
            #{add_fields(object, MAPPING_ONE, config, is_mod)}
            <VendorAddress>
              #{add_fields(object['vendor_address'], ADDRESS_MAP, config, is_mod) if object['vendor_address']}
            </VendorAddress>
            <ShipAddress>
              #{add_fields(object['ship_from_address'], ADDRESS_MAP, config, is_mod) if object['ship_from_address']}
            </ShipAddress>
            #{add_fields(object, MAPPING_TWO, config, is_mod)}
            #{additional_contacts(object)}
            #{contacts(object)}
            #{add_fields(object, MAPPING_THREE, config, is_mod)}
            #{additional_notes(object)}
            #{add_fields(object, MAPPING_FOUR, config, is_mod)}
          XML
        end

        def pre_mapping_logic(initial_object)
          object = initial_object

          object['is_active'] = object['is_active'] || true
          object['firstname'] = object['firstname'] || object['name'].split.first
          object['lastname'] = object['lastname'] || object['name'].split.last
          object['phone'] = object['vendor_address']['phone'] if object['vendor_address']
          if object['mobile'] && object['mobile'] != ''
            object['mobile'] = object['ship_from_address']['phone'] if object['ship_from_address']
          end
          object['reporting_period'] = nil unless REPORTING_PERIODS.include?(object['reporting_period'])
          object['sales_tax_country'] = nil unless SALES_TAX_COUNTRIES.include?(object['sales_tax_country'])

          object
        end

        def additional_contacts(object)
          return "" unless object['additional_contacts'] && object['additional_contacts'].is_a?(Array)
          
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
          return "" unless object['additional_notes'] && object['additional_notes'].is_a?(Array)
          
          fields = ""
          object['additional_notes'].each do |note|
            next unless note && note[:note]

            fields += is_mod ? "<AdditionalNotesMod>" : "<AdditionalNotes>"
            fields += "<NoteID>#{note[:id]}</NoteID>" if is_mod
            fields += "<Note>#{note[:note]}</Note>"
            fields += is_mod ? "</AdditionalNotesMod>" : "</AdditionalNotes>"
          end

          fields
        end

        def contacts(object, is_mod)
          return "" unless object['contacts'] && object['contacts'].is_a?(Array)
          
          fields = ""
          object['contacts'].each do |contact|
            fields += is_mod ? "<ContactsMod>" : "<Contacts>"
            fields += add_fields(contact, CONTACTS_MAP, config)
            fields += additional_contacts(contact)
            fields += is_mod ? "</ContactsMod>" : "</Contacts>"
          end

          fields
        end

        def add_fields(object, mapping, config, is_mod)
          fields = ""
          mapping.each do |map_item|
            return "" if object[:mod_only] && object[:mod_only] != is_mod
            return "" if object[:add_only] && object[:add_only] == is_mod

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
                                config[mapping[:flowlink_name]] ||
                                config["quickbooks_#{mapping[:flowlink_name]}"]

          full_name.nil? ? "" : "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
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
