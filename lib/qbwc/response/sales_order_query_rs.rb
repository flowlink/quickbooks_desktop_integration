module QBWC
  module Response
    class SalesOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying Orders'}),
                                           "orders",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect
        puts to_wombat

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      def objects_to_update
        records.map do |record|
          {
            object_type: 'order',
            object_ref: record['PONumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_wombat
        # TODO finish the map
        records.map do |record|
          object = {
            id: record['PONumber'],
            quickbooks_txn_id: record['TxnID'],
          }

          object
        end
      end
    end
  end
end
