module QBWC
  module Response
    class SalesReceiptQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying Returns'}),
                                           "returns",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      def objects_to_update
        records.map do |record|
          {
            object_type: 'return',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_wombat
        # TODO finish the map
        records.map do |record|
          object = {
            id: record['RefNumber'],
          }

          object
        end
      end
    end
  end
end
