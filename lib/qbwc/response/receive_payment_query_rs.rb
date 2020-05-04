module QBWC
  module Response
    class ReceivePaymentQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying Payments'),
                                           'payments',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        config  = { origin: 'flowlink', connection_id: config[:connection_id]  }.with_indifferent_access
        objects_updated = objects_to_update(config)

        if records.first['request_id'].start_with?('shipment')
          _, shipment_id, _ = records.first['request_id'].split('-')
          Persistence::Object.new(config, {}).update_shipments_with_payment_ids(shipment_id, objects_updated.first)
        else
          Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)
        end

        nil
      end

      def objects_to_update(_config)
        records.map do |record|
          {
            object_type: 'payment',
            object_ref: record['RefNumber'],
            id: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }.with_indifferent_access
        end
      end

      def to_flowlink
        records.map do |record|
          {
            id: record['RefNumber'],
            ref_number: record['RefNumber'],
            qbe_transaction_id: record['TxnID'],
            qbe_id: record['TxnID'],
            transaction_id: record['TxnID'],
            key: ['external_guid'],
            created_at: record['TimeCreated'].to_s,
            modified_at: record['TimeModified'].to_s,
            transaction_number: record['TxnNumber'],
            customer: {
              name: record.dig('CustomerRef','FullName'),
              external_id: record.dig('CustomerRef','ListID'),
              qbe_id: record.dig('CustomerRef', 'ListID')
            },
            ar_account: record.dig('ARAccountRef','FullName'),
            transaction_date: record['Txndate'],
            total: record['TotalAmount'],
            currency_name: record.dig('CurrencyRef','FullName'),
            exchange_rate: record['ExchangeRate'],
            total_amount_in_home_currency: record['TotalAmountInHomeCurrency'],
            payment_method: record.dig('PaymentMethodRef', 'FullName'),
            memo: record['Memo'],
            deposit_to_account_name: record.dig('DepositToAccountRef', 'FullName'),
            unused_payment: record['UnusedPayment'],
            unused_credits: record['UnusedCredits'],
            external_guid: record['ExternalGUID'],
            transactions_applied_to: build_transactions(record),
            relationships: [
              { object: 'customer', key: 'qbe_id' }
            ],
          }
        end
      end

      def build_transactions(record)
        return unless record['AppliedToTxnRet']
        record['AppliedToTxnRet'] = [record['AppliedToTxnRet']] if record['AppliedToTxnRet'].is_a?(Hash)

        record['AppliedToTxnRet'].map do |txn|
          {
            id: txn['TxnID'],
            transaction_id: txn['TxnId'],
            transaction_type: txn['TxnType'],
            transaction_date: txn['TxnDate'],
            ref_number: txn['RefNumber'],
            balance_remaining: txn['BalanceRemaining'],
            amount: txn['Amount'],
            transaction_amount: txn['Amount'],
            discount: txn['DiscountAmount'],
            transaction_discount: txn['DiscountAmount'],
            discount_account_name: txn.dig('DiscountAccountRef', 'FullName'),
            discount_class_name: txn.dig('DiscountClassRef', 'FullName'),
            linked_transactions: build_linked_txns(txn)
          }.compact
        end
      end

      def build_linked_txns(record)
        return unless record['LinkedTxn']
        record['LinkedTxn'] = [record['LinkedTxn']] if record['LinkedTxn'].is_a?(Hash)

        record['LinkedTxn'].map do |txn|
          {
            id: txn['TxnID'],
            transaction_id: txn['TxnId'],
            transaction_type: txn['TxnType'],
            transaction_date: txn['TxnDate'],
            ref_number: txn['RefNumber'],
            link_type: txn['LinkType'],
            amount: txn['Amount']
          }
        end
      end
    end
  end
end
