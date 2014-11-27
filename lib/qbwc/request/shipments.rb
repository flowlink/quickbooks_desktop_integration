module QBWC
  module Request
    class Shipments
      class << self
        def generate_request_queries(objects, params)
          # objects.inject("") do |request, object|
          #   config = { connection_id: params['connection_id'] }.with_indifferent_access
          #   session_id = Persistence::Object.new(config, {}).save_session(object)

          #   request << search_xml(object['id'], session_id)
          # end
          ""
        end

        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Object.new(config, {}).save_session(object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                      else
                        update_xml_to_send(object, params, session_id)
                      end
          end
        end

        def invoice_add_rq
          <<-XML
            <InvoiceAddRq>
              <InvoiceAdd>
                <CustomerRef>
                  <FullName>spree@example.com</FullName>
                </CustomerRef>
                <!-- <TxnDate>DATETYPE</TxnDate> -->
                <RefNumber>R1TT46883</RefNumber>
                <!--
                <ShipMethodRef>
                  <FullName></FullName>
                </ShipMethodRef>
                -->
                <InvoiceLineAdd defMacro="MACROTYPE">
                  <ItemRef>
                    <FullName>SPREE-T-SHIRT</FullName>
                  </ItemRef>
                  <Quantity>2</Quantity>
                  <Rate>103</Rate>
                </InvoiceLineAdd>
              </InvoiceAdd>
            </InvoiceAddRq>
          XML
        end
      end
    end
  end
end
