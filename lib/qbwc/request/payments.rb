module QBWC
  module Request
    class Payments
      class << self
        def generate_request_insert_update(objects, params = {})
          "Generating request or insert/update for: #{}"


          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            extra = "shipment-#{object['order_id']}-" if object.key?('order_id')

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object, extra)

            request << search_xml(object['ref_number'], session_id)
          end
        end

        def search_xml(payment_id, session_id)
          <<-XML

         <ReceivePaymentQueryRq requestID="#{session_id}">
           <RefNumber>#{payment_id}</RefNumber>
         </ReceivePaymentQueryRq>

          XML
        end

        def add_xml_to_send(payment, params, session_id)
          <<-XML
            <ReceivePaymentAddRq requestID="#{session_id}">
              <ReceivePaymentAdd>
                #{payment_xml(payment, params)}
                <IsAutoApply>true</IsAutoApply>
              </ReceivePaymentAdd>
            </ReceivePaymentAddRq>
          XML
        end

        def update_xml_to_send(payment, params, session_id)
          <<-XML
            <ReceivePaymentModRq requestID="#{session_id}">
               <ReceivePaymentMod>
                  <TxnID>#{payment['list_id']}</TxnID>
                  <EditSequence>#{payment['edit_sequence']}</EditSequence>
                  #{payment.key?('invoice_txn_id') ? payment_apply_invoice_xml(payment, params) : payment_xml(payment, params) }
               </ReceivePaymentMod>
            </ReceivePaymentModRq>
          XML
        end

        def payment_apply_invoice_xml(payment, _params)
          <<-XML
              <RefNumber>#{payment['ref_number']}</RefNumber>
              <TotalAmount>#{'%.2f' % payment['amount'].to_f}</TotalAmount>
              <AppliedToTxnMod>
                <TxnID>#{payment['invoice_txn_id']}</TxnID>
                <PaymentAmount>#{'%.2f' % payment['amount'].to_f}</PaymentAmount>
              </AppliedToTxnMod>
          XML
        end

        def payment_xml(payment, _params)
          <<-XML
              <CustomerRef>
                <FullName>#{payment['customer']['name']}</FullName>
              </CustomerRef>
              <RefNumber>#{payment['ref_number']}</RefNumber>
              <TotalAmount>#{'%.2f' % payment['amount'].to_f}</TotalAmount>
              <PaymentMethodRef>
                <FullName>#{payment['payment_method']}</FullName>
              </PaymentMethodRef>
              <Memo>SystumID=#{payment['id']};</Memo>
          XML
        end
      end
    end
  end
end
