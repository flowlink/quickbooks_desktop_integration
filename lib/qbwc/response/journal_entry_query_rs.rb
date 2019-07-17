module QBWC
  module Response
    class JournalEntryQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Journals'),
                                           'journals',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config  = { origin: 'flowlink', connection_id: config[:connection_id]  }.with_indifferent_access
        objects_updated = objects_to_update(config)
        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)

        nil
      end

      def objects_to_update(_config)
        records.map do |record|
          {
            object_type: 'journal',
            object_ref: record['RefNumber'],
            id: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }.with_indifferent_access
        end
      end

    end
  end
end
