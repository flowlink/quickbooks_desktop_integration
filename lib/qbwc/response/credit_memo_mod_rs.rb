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
          check_receive_payment(object)
        end

        Persistence::Object.update_statuses(config, memos)
      end

      def check_receive_payment(obj)
        # return '' unless obj['Other']
        payment_config = {
        }
        payment_payload = {
          parameters: {
            payload_type: 'payment'
          },
          payment: {
            id: "Memo-#{obj['RefNumber']}",
            customer: {
              name: obj['CustomerRef']['FullName']
            },
            invoice_txn_id: obj['TxnId'],
            amount: obj['Amount'],
            credit_amount: obj['Amount'],
            credit_txn_id: obj['Other']
          }
        }
        integration = Persistence::Object.new(payment_config, payment_payload)
        integration.save
      end


    end
  end
end
