module QBWC
  module Response
    class SalesOrderAddRs
      attr_reader :records

      # Successfull persisted sales orders are given here
      def initialize(records)
        @records = records
      end

      def process(config = {})
        orders = records.inject([]) do |orders, record|
          orders << {
            :orders => {
              :id => record['PONumber'],
              # We will need to figure out a way to persist the qb transaction
              # id back to Wombat if we want to update this record later
              :list_id => record['TxnID'],
              :edit_sequence => record['EditSequence']
            }
          }
        end

        {
          # TODO dont think we need this statuses_object key?
          :statuses_objects => {
            :processed => orders,
            :failed => []
          }
        }.with_indifferent_access
      end
    end
  end
end
