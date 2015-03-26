module QBWC
  module Request
    class Customers
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            sanitize_customer(object)

            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << (object[:list_id].to_s.empty?? add_xml_to_send(object, session_id) : update_xml_to_send(object, session_id))
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
    <Name>#{object['email']}</Name>
    <FirstName>#{object['firstname']}</FirstName>
    <LastName>#{object['lastname']}</LastName>
    <BillAddress>
      <Addr1>#{object['billing_address']['address1']}</Addr1>
      <Addr2>#{object['billing_address']['address2']}</Addr2>
      <City>#{object['billing_address']['city']}</City>
      <State>#{object['billing_address']['state']}</State>
      <PostalCode>#{object['billing_address']['zipcode']}</PostalCode>
      <Country>#{object['billing_address']['country']}</Country>
    </BillAddress>
    <ShipAddress>
      <Addr1>#{object['shipping_address']['address1']}</Addr1>
      <Addr2>#{object['shipping_address']['address2']}</Addr2>
      <City>#{object['shipping_address']['city']}</City>
      <State>#{object['shipping_address']['state']}</State>
      <PostalCode>#{object['shipping_address']['zipcode']}</PostalCode>
      <Country>#{object['shipping_address']['country']}</Country>
    </ShipAddress>
    <Phone>#{object['billing_address']['phone']}</Phone>
    <AltPhone>#{object['shipping_address']['phone']}</AltPhone>
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
      <Name>#{object['email']}</Name>
      <FirstName>#{object['firstname']}</FirstName>
      <LastName>#{object['lastname']}</LastName>
      <BillAddress>
        <Addr1>#{object['billing_address']['address1']}</Addr1>
        <Addr2>#{object['billing_address']['address2']}</Addr2>
        <City>#{object['billing_address']['city']}</City>
        <State>#{object['billing_address']['state']}</State>
        <PostalCode>#{object['billing_address']['zipcode']}</PostalCode>
        <Country>#{object['billing_address']['country']}</Country>
      </BillAddress>
      <ShipAddress>
        <Addr1>#{object['shipping_address']['address1']}</Addr1>
        <Addr2>#{object['shipping_address']['address2']}</Addr2>
        <City>#{object['shipping_address']['city']}</City>
        <State>#{object['shipping_address']['state']}</State>
        <PostalCode>#{object['shipping_address']['zipcode']}</PostalCode>
        <Country>#{object['shipping_address']['country']}</Country>
      </ShipAddress>
      <Phone>#{object['billing_address']['phone']}</Phone>
      <AltPhone>#{object['shipping_address']['phone']}</AltPhone>
      <Email>#{object['email']}</Email>
   </CustomerMod>
</CustomerModRq>
          XML
        end

        private

        def sanitize_customer(customer)
          customer['billing_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['billing_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['billing_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['billing_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['billing_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['billing_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['address1'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['address2'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['city'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['state'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['zipcode'].gsub!(/[^0-9A-Za-z\s]/, '')
          customer['shipping_address']['country'].gsub!(/[^0-9A-Za-z\s]/, '')
        end

      end
    end
  end
end
