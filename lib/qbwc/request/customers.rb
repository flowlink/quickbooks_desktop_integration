module QBWC
  module Request
    class Customers
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

            request << search_xml(object['email'], session_id)
          end
        end

        def search_xml(object_id, session_id)
          <<-XML
<CustomerQueryRq requestID="#{session_id}">
  <MaxReturned>50</MaxReturned>
  <NameRangeFilter>
    <FromName>#{object_id}</FromName>
    <ToName>#{object_id}</ToName>
  </NameRangeFilter>
</CustomerQueryRq>
          XML
        end

        def add_xml_to_send(object, session_id)
          <<-XML
<CustomerAddRq requestID="#{session_id}">
   <CustomerAdd>
    <Name>#{object['name']}</Name>
    #{"<CompanyName>#{object['company']}</CompanyName>" unless object['company'].empty?}
    <FirstName>#{object['firstname'].empty? ? object['name'].split.first : object['firstname']}</FirstName>
    #{"<LastName>#{object['lastname'] || object['name'].split.last}</LastName>" unless object['lastname'].empty?}
    <BillAddress>
      <Addr1>#{object['billing_address']['address1'] if object['billing_address']}</Addr1>
      #{"<Addr2>#{object['billing_address']['address2']}</Addr2>" if object['billing_address'] && object['billing_address']['address2']}
      <City>#{object['billing_address']['city'] if object['billing_address']}</City>
      <State>#{object['billing_address']['state'] if object['billing_address']}</State>
      <PostalCode>#{object['billing_address']['zipcode'] if object['billing_address']}</PostalCode>
      <Country>#{object['billing_address']['country'] if object['billing_address']}</Country>
    </BillAddress>
    <ShipAddress>
      <Addr1>#{object['shipping_address']['address1'] if object['shipping_address']}</Addr1>
      #{"<Addr2>#{object['shipping_address']['address2']}</Addr2>" if object['shipping_address'] && object['shipping_address']['address2']}
      <City>#{object['shipping_address']['city'] if object['shipping_address']}</City>
      <State>#{object['shipping_address']['state'] if object['shipping_address']}</State>
      <PostalCode>#{object['shipping_address']['zipcode'] if object['shipping_address']}</PostalCode>
      <Country>#{object['shipping_address']['country'] if object['shipping_address']}</Country>
    </ShipAddress>
    <Phone>#{object['billing_address']['phone'] if object['billing_address']}</Phone>
    <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
    <Email>#{object['email']}</Email>
   </CustomerAdd>
</CustomerAddRq>
          XML
        end

        def update_xml_to_send(object, session_id)
          <<-XML
<CustomerModRq requestID="#{session_id}">
   <CustomerMod>
      <ListID>#{object['list_id']}</ListID>
      <EditSequence>#{object['edit_sequence']}</EditSequence>
      <Name>#{object['name']}</Name>
      <CompanyName>#{object['company']}</CompanyName>
      <FirstName>#{object['firstname']}</FirstName>
      <LastName>#{object['lastname']}</LastName>
      <BillAddress>
        <Addr1>#{object['billing_address']['address1'] if object['billing_address']}</Addr1>
        <Addr2>#{object['billing_address']['address2'] if object['billing_address']}</Addr2>
        <City>#{object['billing_address']['city'] if object['billing_address']}</City>
        <State>#{object['billing_address']['state'] if object['billing_address']}</State>
        <PostalCode>#{object['billing_address']['zipcode'] if object['billing_address']}</PostalCode>
        <Country>#{object['billing_address']['country'] if object['billing_address']}</Country>
      </BillAddress>
      <ShipAddress>
        <Addr1>#{object['shipping_address']['address1'] if object['shipping_address']}</Addr1>
        <Addr2>#{object['shipping_address']['address2'] if object['shipping_address']}</Addr2>
        <City>#{object['shipping_address']['city'] if object['shipping_address']}</City>
        <State>#{object['shipping_address']['state'] if object['shipping_address']}</State>
        <PostalCode>#{object['shipping_address']['zipcode'] if object['shipping_address']}</PostalCode>
        <Country>#{object['shipping_address']['country'] if object['shipping_address']}</Country>
      </ShipAddress>
      <Phone>#{object['billing_address']['phone'] if object['billing_address']}</Phone>
      <AltPhone>#{object['shipping_address']['phone'] if object['shipping_address']}</AltPhone>
      <Email>#{object['email']}</Email>
   </CustomerMod>
</CustomerModRq>
          XML
        end

        private

        def sanitize_customer(customer)
          # customer['company'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['company']
          customer['firstname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['firstname']
          # customer['name'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['name']
          customer['lastname'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['lastname']
          # customer['email'] = nil unless customer['email'] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

          customer['billing_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['address1']
          customer['billing_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['address2']
          customer['billing_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['city']
          customer['billing_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['state']
          customer['billing_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['zipcode']
          customer['billing_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['country']
          customer['billing_address']['phone'].gsub!(/[^0-9A-Za-z\s]/, '') if customer['billing_address'] && customer['billing_address']['phone']
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
