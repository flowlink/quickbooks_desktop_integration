module QBWC
  module Request
    class Vendors
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << (object[:list_id].to_s.empty? ? add_xml_to_send(object, session_id) : update_xml_to_send(object, session_id))
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object['name'], session_id)
          end
        end

        def search_xml(object_id, session_id)
          <<-XML
<VendorQueryRq requestID="#{session_id}">
  <MaxReturned>50</MaxReturned>
  <NameRangeFilter>
    <FromName>#{object_id}</FromName>
    <ToName>#{object_id}</ToName>
  </NameRangeFilter>
</VendorQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id)
          <<-XML
<VendorAddRq requestID="#{session_id}">
   <VendorAdd>
    <Name>#{object['name']}</Name>
    #{"<CompanyName>#{object['company']}</CompanyName>" unless object['company'].empty?}
    <FirstName>#{object['firstname'].empty? ? object['name'].split.first : object['firstname']}</FirstName>
    #{"<LastName>#{object['lastname'] || object['name'].split.last}</LastName>" unless object['lastname'].empty?}
    <VendorAddress>
      <Addr1>#{object['vendor_address']['address1'] if object['vendor_address']}</Addr1>
      #{"<Addr2>#{object['vendor_address']['address2']}</Addr2>" if object['vendor_address'] && object['vendor_address']['address2']}
      <City>#{object['vendor_address']['city'] if object['vendor_address']}</City>
      <State>#{object['vendor_address']['state'] if object['vendor_address']}</State>
      <PostalCode>#{object['vendor_address']['zipcode'] if object['vendor_address']}</PostalCode>
      <Country>#{object['vendor_address']['country'] if object['vendor_address']}</Country>
    </VendorAddress>
    <ShipAddress>
      <Addr1>#{object['shipping_address']['address1'] if object['shipping_address']}</Addr1>
      #{"<Addr2>#{object['shipping_address']['address2']}</Addr2>" if object['shipping_address'] && object['shipping_address']['address2']}
      <City>#{object['shipping_address']['city'] if object['shipping_address']}</City>
      <State>#{object['shipping_address']['state'] if object['shipping_address']}</State>
      <PostalCode>#{object['shipping_address']['zipcode'] if object['shipping_address']}</PostalCode>
      <Country>#{object['shipping_address']['country'] if object['shipping_address']}</Country>
    </ShipAddress>
    <Phone>#{object['vendor_address']['phone'] if object['vendor_address']}</Phone>
    <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
    <Email>#{object['email']}</Email>
   </VendorAdd>
</VendorAddRq>
          XML
        end

        def update_xml_to_send(object, session_id)
          <<-XML
<VendorModRq requestID="#{session_id}">
   <VendorMod>
      <ListID>#{object['list_id']}</ListID>
      <EditSequence>#{object['edit_sequence']}</EditSequence>
      <Name>#{object['name']}</Name>
      <CompanyName>#{object['company']}</CompanyName>
      <FirstName>#{object['firstname']}</FirstName>
      <LastName>#{object['lastname']}</LastName>
      <VendorAddress>
        <Addr1>#{object['vendor_address']['address1'] if object['vendor_address']}</Addr1>
        <Addr2>#{object['vendor_address']['address2'] if object['vendor_address']}</Addr2>
        <City>#{object['vendor_address']['city'] if object['vendor_address']}</City>
        <State>#{object['vendor_address']['state'] if object['vendor_address']}</State>
        <PostalCode>#{object['vendor_address']['zipcode'] if object['vendor_address']}</PostalCode>
        <Country>#{object['vendor_address']['country'] if object['vendor_address']}</Country>
      </VendorAddress>
      <ShipAddress>
        <Addr1>#{object['shipping_address']['address1'] if object['shipping_address']}</Addr1>
        <Addr2>#{object['shipping_address']['address2'] if object['shipping_address']}</Addr2>
        <City>#{object['shipping_address']['city'] if object['shipping_address']}</City>
        <State>#{object['shipping_address']['state'] if object['shipping_address']}</State>
        <PostalCode>#{object['shipping_address']['zipcode'] if object['shipping_address']}</PostalCode>
        <Country>#{object['shipping_address']['country'] if object['shipping_address']}</Country>
      </ShipAddress>
      <Phone>#{object['vendor_address']['phone'] if object['vendor_address']}</Phone>
      <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
      <Email>#{object['email']}</Email>
   </VendorMod>
</VendorModRq>
          XML
        end

        private

        def sanitize_customer(customer)
          # customer['company'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['company']
          customer['firstname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['firstname']
          # customer['name'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['name']
          customer['lastname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['lastname']
          # customer['email'] = nil unless customer['email'] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

          customer['vendor_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['address1']
          customer['vendor_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['address2']
          customer['vendor_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['city']
          customer['vendor_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['state']
          customer['vendor_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['zipcode']
          customer['vendor_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['country']
          customer['vendor_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['vendor_address'] && customer['vendor_address']['phone']
          customer['shipping_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['address1']
          customer['shipping_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['address2']
          customer['shipping_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['city']
          customer['shipping_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['state']
          customer['shipping_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['zipcode']
          customer['shipping_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['phone']
          customer['shipping_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['shipping_address'] && customer['shipping_address']['country']
        end
      end
    end
  end
end
