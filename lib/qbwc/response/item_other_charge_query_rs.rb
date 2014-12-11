module QBWC
  module Response
    class ItemOtherChargeQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying adjustments'}),
                                           "adjustments",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config = config.merge({ origin: 'wombat' })
        object_persistence = Persistence::Object.new config
        object_persistence.update_objects_with_query_results(objects_to_update)

        nil
      end

      private

      def objects_to_update
        records.map do |record|
          {
            object_type: 'adjustment',
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end
    end
  end
end
