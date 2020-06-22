module QBWC
  module Response
    class CreditMemoModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Updating Credit Memo'),
                                           'creditmemos',
                                           error[:request_id])
        end
      end

      def process(config)
        return { 'statuses_objects' => nil } if records.empty?

        memos = []
        records.each do |object|
          memos << { 
            creditmemos: {
              id: object['TxnId'],
              list_id: object['TxnId'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, memos)
      end


    end
  end
end
