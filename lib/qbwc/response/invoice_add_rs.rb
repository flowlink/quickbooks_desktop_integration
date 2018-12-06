module QBWC
  module Response
    class InvoiceAddRs
      attr_reader :records

      # Successfull persisted sales invoices are given here
      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Adding invoices'),
                                           'invoices',
                                           error[:request_id])
        end
      end

      def process(config = {})
        invoices = records.inject([]) do |invoices, record|
          invoices << {
            invoices: {
              id: record['RefNumber'],
              list_id: record['TxnID'],
              edit_sequence: record['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, invoices)
      end
    end
  end
end
