module QBWC
  module Response
    class VendorQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Vendors'),
                                           'vendors',
                                           error[:request_id])
        end
      end

      def process(config)
        return if records.empty?

        puts "Config for customer query: #{config}"

        receive_configs = config[:receive] || []
        vendor_params = receive_configs.find { |c| c['vendors'] }

        if vendor_params
          payload = { vendors: to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          vendor_params['vendors']['quickbooks_since'] = last_time_modified
          vendor_params['vendors']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = vendor_params['vendors']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end
        config  = { origin: 'flowlink', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      private

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      def objects_to_update
        records.map do |record|
          {
            object_type: 'vendor',
            email: record['Name'],
            name: record['Name'],
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_flowlink
        records.map do |record|
          puts "Vendor QBE object: #{record}"
          {
            id: record['ListID'],
            qbe_id: record['ListID'],
            key: 'qbe_id',
            name: record['Name'],
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            is_active: record['IsActive'],
            vendor_address: {
              address1: record.dig('VendorAddress', 'Addr1'),
              address2: record.dig('VendorAddress', 'Addr2'),
              address3: record.dig('VendorAddress', 'Addr3'),
              address4: record.dig('VendorAddress', 'Addr4'),
              address5: record.dig('VendorAddress', 'Addr5'),
              city: record.dig('VendorAddress', 'City'),
              state: record.dig('VendorAddress', 'State'),
              country: record.dig('VendorAddress', 'Country'),
              zip_code: record.dig('VendorAddress', 'PostalCode'),
              note: record.dig("VendorAddress", "Note")
            }.compact,
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
              note: record.dig("ShipAddress", "Note")
            }.compact,
            vendor_type_name: record.dig('VendorTypeRef', 'FullName'),
            billing_rate_name: record.dig('BillingRateRef', 'FullName'),
            sales_tax_code_name: record.dig('SalesTaxCodeRef', 'FullName'),
            sales_tax_return_name: record.dig('SalesTaxReturnRef', 'FullName'),
            tax_on_purchases_account_name: record.dig('TaxOnPurchasesAccountRef', 'FullName'),
            tax_on_sales_account_name: record.dig('TaxOnSalesAccountRef', 'FullName'),
            currency_name: record.dig('CurrencyRef', 'FullName'),
            terms: record.dig('TermsRef', 'FullName'),
            vendor_tax_ident: record['VendorTaxIdent'],
            name_on_check: record['NameOnCheck'],
            is_vendor_eligible_for_1099: record['IsVendorEligibleFor1099'],
            balance: record['Balance'],
            phone: record['Phone'],
            alternative_phone: record['AltPhone'],
            fax: record['Fax'],
            email: record['Email'],
            cc: record['Cc'],
            contact: record['Contact'],
            alternative_contact: record['AltContact'],
            account_number: record['AccountNumber'],
            notes: record['Notes'],
            credit_limit: record['CreditLimit'],
            sales_tax_country: record['SalesTaxCountry'],
            is_sales_tax_agency: record['IsSalesTaxAgency'],
            tax_registration_number: record['TaxRegistrationNumber'],
            reporting_period: record['ReportingPeriod'],
            is_tax_tracked_on_purchases: record['IsTaxTrackedOnPurchases'],
            is_tax_tracked_on_sales: record['IsTaxTrackedOnSales'],
            is_tax_on_tax: record['IsTaxOnTax'],
            qbe_external_guid: record['ExternalGUID'],
            additional_notes: additional_notes(record),
            additional_contacts: additional_contacts(record),
            contacts: contacts(record)
          }.compact
        end
      end

      def additional_notes(record)
        return unless record['AdditionalNotesRet']
        record['AdditionalNotesRet'] = [record['AdditionalNotesRet']] if record['AdditionalNotesRet'].is_a?(Hash)

        record['AdditionalNotesRet'].to_a.map do |note|
          {
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

# TODO: Still need these fields when getting vendors
# <PrefillAccountRef> <!-- must occur 0 - 3 times -->
#         <ListID >IDTYPE</ListID> <!-- optional -->
#         <FullName >STRTYPE</FullName> <!-- optional -->
# </PrefillAccountRef>
