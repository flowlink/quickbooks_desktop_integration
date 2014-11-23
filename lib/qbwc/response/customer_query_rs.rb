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
                                           error.merge({context: 'Querying Customers'}),
                                           "customers",
                                           error[:request_id])
        end
      end

      def process(config)
        return if records.empty?

        puts records.inspect

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      private

      def objects_to_update
        records.map do |record|
          {
            object_type: 'customer',
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_wombat
        records.map do |record|
          object = {
            id: record['ListID'],
            name: record['Name'],
            description: record['FullName'],
            sku: record['Name']
          }
          object
        end
      end
    end
  end
end
