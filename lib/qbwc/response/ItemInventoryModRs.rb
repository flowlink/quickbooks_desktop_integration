module QBWC
  module Response
    class ItemInventoryModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Updating products'}),
                                           "products",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?


        # TODO Error handling

        # &lt;QBXML&gt;
        # &lt;QBXMLMsgsRs&gt;
        # &lt;ItemInventoryAddRs statusCode="3100" statusSeverity="Error" statusMessage="The name &amp;quot;SPREE-T-SHIRT697877&amp;quot; of the list element is already in use." /&gt;
        # &lt;/QBXMLMsgsRs&gt;
        # &lt;/QBXML&gt;
        # </response><hresult /><message /></receiveResponseXML></soap:Body></soap:Envelope>

puts " \n\n\n **** Records: #{records.inspect} \n\n"

        products = []
        records.each do |object|
          products << { :products => {
                                       :id            => object['Name'],
                                       :list_id       => object['ListID'],
                                       :edit_sequence => object['EditSequence']
                                      }
                      }
        end

        Persistence::Object.update_statuses(config, products)
      end
    end
  end
end
