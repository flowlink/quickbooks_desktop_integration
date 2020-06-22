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
          puts "*" * 81
          puts "object in process"
          puts object.inspect
          puts "*" * 81
          memos << { 
            creditmemos: {
              id: object['TxnId'],
              list_id: object['TxnId'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, memos)

        # payment_config = {
        # }
        # payment_payload = {
        #   parameters: {
        #     payload_type: 'payment'
        #   },
        #   payment: {
        #     invoice_txn_id: ''
        #     amount: 1.4
        #   }
        # }
        # integration = Persistence::Object.new(payment_config, payment_payload)
        # integration.save
      end


    end
  end
end
