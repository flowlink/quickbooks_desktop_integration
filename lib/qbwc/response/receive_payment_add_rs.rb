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
            "orders",
            error[:request_id]
          )
        end
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?

        objects = records.map do |object|
          {
            payments: {
              id: object['RefNumber'],
              object_ref: object['RefNumber'],
              list_id: object['TxnID'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
