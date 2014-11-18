module QBWC
  module Response
    class ItemInventoryModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        error = errors.first
        Persistence::Object.new(config).create_error_notifications( error.merge({context: 'Modifying products'}),
                                                                    "products",
                                                                    error[:request_id])
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

        { :statuses_objects => { :processed => products, :failed => [] } }.with_indifferent_access
      end
    end
  end
end
