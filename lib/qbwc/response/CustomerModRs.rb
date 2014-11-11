module QBWC
  module Response
    class CustomerModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?


        # TODO Error handling

        # &lt;QBXML&gt;
        # &lt;QBXMLMsgsRs&gt;
        # &lt;ItemInventoryAddRs statusCode="3100" statusSeverity="Error" statusMessage="The name &amp;quot;SPREE-T-SHIRT697877&amp;quot; of the list element is already in use." /&gt;
        # &lt;/QBXMLMsgsRs&gt;
        # &lt;/QBXML&gt;
        # </response><hresult /><message /></receiveResponseXML></soap:Body></soap:Envelope>

        puts " \n\n\n **** Records: #{records.inspect} \n\n"

        objects = records.map do |object|
          { customers: {
            id: object['Name'],
            list_id: object['ListID'],
            edit_sequence: object['EditSequence'] } }
        end

        { statuses_objects: { processed: objects, failed: [] } }.with_indifferent_access

        # Move files and create  notifications
      end
    end
  end
end
