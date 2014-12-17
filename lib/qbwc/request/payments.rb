module QBWC
  module Request
    class Payments
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << update_xml_to_send(object, params, session_id)
          end
        end

        def generate_request_queries(objects, params)
          objects.inject("") do |request, object|
            extra = "shipment-#{object['shipment_id']}-" if object.has_key?('shipment_id')
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object, extra)
            request << self.search_xml(object.has_key?('product_id') ? object['product_id'] : object['id'], session_id)
          end
        end

        def search_xml(payment_id, session_id)
          <<-XML

         <ReceivePaymentQueryRq requestID="#{session_id}">
           <RefNumber>#{payment_id}</RefNumber>
         </ReceivePaymentQueryRq>

          XML
        end

        def update_xml_to_send(payment, params, session_id)
          <<-XML
            <ReceivePaymentModRq requestID="#{session_id}">
               <ReceivePaymentMod>
                  <TxnID>#{payment['list_id']}</TxnID>
                  <EditSequence>#{payment['edit_sequence']}</EditSequence>
                  #{payment_xml(payment, params)}
               </ReceivePaymentMod>
            </ReceivePaymentModRq>
          XML
        end

        def payment_xml(payment, params)
          <<-XML
              <RefNumber>#{payment['object_ref']}</RefNumber>
              <AppliedToTxnMod>
                <TxnID>#{payment['invoice_txn_id']}</TxnID>
                <PaymentAmount>#{payment['amount'].to_f}</PaymentAmount>
              </AppliedToTxnMod>
          XML
        end

      end
    end
  end
end
