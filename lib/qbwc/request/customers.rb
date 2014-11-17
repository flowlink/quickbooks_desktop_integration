module QBWC
  module Request
    class Customers
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            request << (object[:list_id].to_s.empty?? add_xml_to_send(object) : update_xml_to_send(object))
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') { |request, object| request << search_xml(object['id']) }
        end

        def search_xml(object_id)
          <<-XML
<CustomerQueryRq>
  <MaxReturned>50</MaxReturned>
  <NameFilter>
    <MatchCriterion>StartsWith</MatchCriterion>
    <Name>#{object_id}</Name>
  </NameFilter>
</CustomerQueryRq>
          XML
        end

        def add_xml_to_send(object)
          <<-XML
<CustomerAddRq>
   <CustomerAdd>
    <Name>#{object['id']}</Name>
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

        def update_xml_to_send(object)
          <<-XML
<CustomerModRq>
   <CustomerMod>
      <ListID>#{object['list_id']}</ListID>
      <EditSequence>#{object['edit_sequence']}</EditSequence>
      <Name>#{object['id']}</Name>
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
      end
    end
  end
end
