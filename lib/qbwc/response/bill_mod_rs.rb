module QBWC
  module Response
    class BillModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Updating Bills'),
                                           'bills',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?

        objects = records.map do |object|
          { bills: {
            id: object['Name'],
            list_id: object['ListID'],
            edit_sequence: object['EditSequence'] } }
        end

        Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
