module QBWC
  module Response
    class ReceivePaymentAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(
            config,
            error.merge(context: 'Adding Payments'),
            'payments',
            error[:request_id]
          )
        end
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?

        objects = records.map do |record|
          {
            payments: {
              id: record['RefNumber'],
              object_ref: record['RefNumber'],
              list_id: record['TxnID'],
              edit_sequence: record['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
