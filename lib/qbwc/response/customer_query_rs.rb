module QBWC
  module Response
    class CustomerQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Customers'),
                                           'customers',
                                           error[:request_id])
        end
      end

      def process(config)
        return if records.empty?

        puts "Config for customer query: #{config}"

        receive_configs = config[:receive] || []
        customer_params = receive_configs.find { |c| c['customers'] }

        if customer_params
          payload = { customers: to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == 'origin'}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          customer_params['customers']['quickbooks_since'] = last_time_modified
          customer_params['customers']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = customer_params['customers']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)

        nil
      end

      private

      def objects_to_update
        # puts "Objects to update: #{records}"
        records.map do |record|
          {
            object_type: 'customer',
            email: record['Name'],
            name: record['Name'],
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end


      def to_flowlink
        records.map do |record|
          puts "Customer QBE object: #{record}"
          {
            id: record['ListID'],
            list_id: record['ListID'],
            qbe_id: record['ListID'],
            key: 'qbe_id',
            external_id: record['ListID'],
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            name: record['Name'],
            full_name: record['FullName'],
            email: record['Email'],
            billing_address: {
              address1: record.dig('BillAddress', 'Addr1'),
              address2: record.dig('BillAddress', 'Addr2'),
              address3: record.dig('BillAddress', 'Addr3'),
              address4: record.dig('BillAddress', 'Addr4'),
              address5: record.dig('BillAddress', 'Addr5'),
              city: record.dig('BillAddress', 'City'),
              state: record.dig('BillAddress', 'State'),
              country: record.dig('BillAddress', 'Country'),
              zip_code: record.dig('BillAddress', 'PostalCode'),
              note: record.dig('BillAddress', 'Note')
            }.compact,
            balance: record['Balance'],
            total_balance: record['TotalBalance'],
            job_status: record['JobStatus'],
            shipping_address: {
              address1: record.dig('ShipAddress', 'Addr1'),
              address2: record.dig('ShipAddress', 'Addr2'),
              address3: record.dig('ShipAddress', 'Addr3'),
              address4: record.dig('ShipAddress', 'Addr4'),
              address5: record.dig('ShipAddress', 'Addr5'),
              city: record.dig('ShipAddress', 'City'),
              state: record.dig('ShipAddress', 'State'),
              country: record.dig('ShipAddress', 'Country'),
              zip_code: record.dig('ShipAddress', 'PostalCode'),
              note: record.dig('ShipAddress', 'Note')
            }.compact,
            ship_to_addresses: ship_to_addresses(record),
            class_name: record.dig('ClassRef', 'FullName'),
            sales_rep: record.dig('SalesRepRef', 'FullName'),
            is_active: record['IsActive'],
            phone: record['Phone'],
            alternative_phone: record['AltPhone'],
            fax: record['Fax'],
            contact: record['Contact'],
            alternative_contact: record['AltContact'],
            sub_level: record['Sublevel'],
            first_name: record['FirstName'],
            middle_name: record['MiddleName'],
            last_name: record['LastName'],            
            company: record['CompanyName'],
            salutation: record['Salutation'],
            job_title: record['JobTitle'],
            cc: record['Cc'],
            sales_tax_country: record['SalesTaxCountry'],
            resale_number: record['ResaleNumber'],
            account_number: record['AccountNumber'],
            credit_limit: record['CreditLimit'],
            job_start_date: record['JobStartDate'].to_s,
            job_predicted_end_date: record['JobProjectedEndDate'].to_s,
            job_end_date: record['JobEndDate'].to_s,
            job_description: record['JobDesc'],
            notes: record['Notes'],
            preferred_delivery_method: record['PreferredDeliveryMethod'],
            external_guid: record['ExternalGUID'],
            tax_registration_number: record['TaxRegistrationNumber'],
            currency_name: record.dig('CurrencyRef', 'FullName'),
            parent_name: record.dig('ParentRef', 'FullName'),
            customer_type_name: record.dig('CustomerTypeRef', 'FullName'),
            terms: record.dig('TermsRef', 'FullName'),
            sales_tax_code: record.dig('SalesTaxCodeRef', 'FullName'),
            tax_ref: record.dig('ItemSalesTaxRef', 'FullName'),
            preferred_payment_method_name: record.dig('PreferredPaymentMethodRef', 'FullName'),
            job_type_name: record.dig('JobTypeRef', 'FullName'),
            price_level_name: record.dig('PriceLevelRef', 'FullName'),
            additional_notes: additional_notes(record),
            additional_contacts: additional_contacts(record),
            contacts: contacts(record)
          }.compact
        end
      end

      def ship_to_addresses(record)
        record['ShipToAddress'].to_a.map do |obj|
          {
            name: obj['Name'],
            address1: obj['Addr1'],
            address2: obj['Addr2'],
            address3: obj['Addr3'],
            address4: obj['Addr4'],
            address5: obj['Addr5'],
            city: obj['City'],
            state: obj['State'],
            country: obj['Country'],
            zip_code: obj['PostalCode'],
            note: obj['Note'],
            default_ship_to: obj['DefaultShipTo']
          }.compact
        end
      end

      def additional_notes(record)
        return unless record['AdditionalNotesRet']
        record['AdditionalNotesRet'] = [record['AdditionalNotesRet']] if record['AdditionalNotesRet'].is_a?(Hash)

        record['AdditionalNotesRet'].to_a.map do |note|
          {
            id: note['NoteID'],
            date: note['Date'],
            note: note['Note']
          }
        end
      end

      def additional_contacts(record)
        return unless record['AdditionalContactRef']
        record['AdditionalContactRef'] = [record['AdditionalContactRef']] if record['AdditionalContactRef'].is_a?(Hash)

        record['AdditionalContactRef'].to_a.map do |contact|
          {
            contact_name: contact['ContactName'],
            contact_value: contact['ContactValue']
          }
        end
      end

      def contacts(record)
        return unless record['ContactsRet']
        record['ContactsRet'] = [record['ContactsRet']] if record['ContactsRet'].is_a?(Hash)

        record['ContactsRet'].to_a.map do |contact|
          {
            id: contact['ListID'],
            list_id: contact['ListID'],
            qbe_id: contact['ListID'],
            key: 'qbe_id',
            external_id: contact['ListID'],
            created_at: contact['TimeCreated'].to_s,
            modified_at: contact['TimeModified'].to_s,
            first_name: contact['FirstName'],
            middle_name: contact['MiddleName'],
            last_name: contact['LastName'],
            salutation: contact['Salutation'],
            contact: contact['Contact'],
            job_title: contact['JobTitle'],
            additional_contacts: additional_contacts(contact)
          }
        end
      end
    end
  end
end

# TODO: Still need these fields when getting customers
# <CreditCardInfo> <!-- optional -->
#         <CreditCardNumber >STRTYPE</CreditCardNumber> <!-- optional -->
#         <ExpirationMonth >INTTYPE</ExpirationMonth> <!-- optional -->
#         <ExpirationYear >INTTYPE</ExpirationYear> <!-- optional -->
#         <NameOnCard >STRTYPE</NameOnCard> <!-- optional -->
#         <CreditCardAddress >STRTYPE</CreditCardAddress> <!-- optional -->
#         <CreditCardPostalCode >STRTYPE</CreditCardPostalCode> <!-- optional -->
# </CreditCardInfo>
