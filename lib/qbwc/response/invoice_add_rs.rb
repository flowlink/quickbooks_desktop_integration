module QBWC
  module Response
    class InvoiceAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(
            config,
            error.merge(context: 'Adding Shipments'),
            "shipments",
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
              list_id: object['TxnID'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        # NOTE Not clear yet we need to persist these payments separately
        # Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
