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
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_flowlink
        records.map do |record|
          puts "Vendor QBE object: #{record}"
          object = {
            id: record['ListID'],
            name: record['Name']
          }
          object
        end
      end
    end
  end
end
