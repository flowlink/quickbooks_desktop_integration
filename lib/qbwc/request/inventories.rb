module QBWC
  module Request
    class Inventories

      class << self
        def generate_request_insert_update(objects)
          objects.inject('') do |request, object|
            request << (object[:list_id].present?? add_xml_to_send(object) : update_xml_to_send(object))
          end
        end

        def generate_request_queries(objects)
          objects.inject('') { |request, object| request << search_xml(object['id']) }
        end

        def search_xml(object_id)
          <<-XML
<ItemInventoryQueryRq>
  <MaxReturned>50</MaxReturned>
  <NameFilter>
    <MatchCriterion>StartsWith</MatchCriterion>
    <Name>#{object_id}</Name>
  </NameFilter>
</ItemInventoryQueryRq>
          XML
        end

        def add_xml_to_send(object)
          <<-XML
<ItemInventoryAddRq>
   <ItemInventoryAdd>
      <Name>#{object['id']}</Name>
      <QuantityOnHand>#{object['quantity']}</QuantityOnHand>
   </ItemInventoryAdd>
</ItemInventoryAddRq>
          XML
        end

        def update_xml_to_send(object)
          <<-XML
<ItemInventoryModRq>
   <ItemInventoryMod>
      <ListID>IDTYPE</ListID> <!-- required -->
      <EditSequence>STRTYPE</EditSequence> <!-- required -->
      <Name>#{object['id']}</Name>
      <QuantityOnHand>#{object['quantity']}</QuantityOnHand>
   </ItemInventoryMod>
</ItemInventoryModRq>
          XML
        end
      end
    end
  end
end
