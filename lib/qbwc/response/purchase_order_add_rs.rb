module QBWC
  module Response
    class PurchaseOrderAddRs
      attr_reader :records

      # Successfull persisted sales purchase_orders are given here
      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Adding purchase_orders'),
                                           'purchase_orders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        purchase_orders = records.inject([]) do |purchase_orders, record|
          purchase_orders << {
            purchase_orders: {
              id: record['RefNumber'],
              list_id: record['TxnID'],
              edit_sequence: record['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, purchase_orders)
      end
    end
  end
end
