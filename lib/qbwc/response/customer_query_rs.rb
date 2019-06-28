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
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

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
          # puts "Customer QBE object: #{record}"
          {
            id: record['ListID'],
            list_id: record['ListID'],
            qbe_id: record['ListID'],
            external_id: record['ListID'],
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            name: record['Name'],
            full_name: record['FullName'],
            email: record['Email'],
            billing_address: {
              address1: record.dig("BillAddress", "Addr1"),
              address2: record.dig("BillAddress", "Addr2"),
              city: record.dig("BillAddress", "City"),
              state: record.dig("BillAddress", "State"),
              country: record.dig("BillAddress", "Country"),
              zip_code: record.dig("BillAddress", "PostalCode")
            }.compact,
            balance: record['Balance'],
            total_balance: record['TotalBalance'],
            job_status: record['JobStatus'],
            shipping_address: {
              address1: record.dig("ShipAddress", "Addr1"),
              address2: record.dig("ShipAddress", "Addr2"),
              city: record.dig("ShipAddress", "City"),
              state: record.dig("ShipAddress", "State"),
              country: record.dig("ShipAddress", "Country"),
              zip_code: record.dig("ShipAddress", "PostalCode")
            }.compact,
            class_name: record.dig("ClassRef", "FullName"),
            sales_rep: record.dig("SalesRepRef", "FullName"),
            is_active: record['IsActive'],
            sub_level: record['Sublevel'],
            first_name: record['FirstName'],
            last_name: record['LastName']
          }.compact
        end
      end
    end
  end
end
