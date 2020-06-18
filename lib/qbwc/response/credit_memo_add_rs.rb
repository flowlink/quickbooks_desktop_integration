module QBWC
  module Response
    class CreditMemoAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Adding Credit Memo'),
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

        Persistence::Object.update_statuses(config, products)

        # TODO: Do I trigger a receive payment request from here?
        # <ReceivePaymentAddRq requestID="#{session_id}">
          # <ReceivePaymentAdd>
        # <AppliedToTxnAdd> <!-- optional, may repeat -->
        #   <TxnID  useMacro="MACROTYPE">IDTYPE</TxnID> <!-- required -->
        #   <PaymentAmount >AMTTYPE</PaymentAmount> <!-- optional -->
        #   <SetCredit> <!-- optional, may repeat -->
        #           <CreditTxnID  useMacro="MACROTYPE">IDTYPE</CreditTxnID> <!-- required -->
        #           <AppliedAmount >AMTTYPE</AppliedAmount> <!-- required -->
        #           <Override >BOOLTYPE</Override> <!-- optional -->
        #   </SetCredit>

      end


    end
  end
end
