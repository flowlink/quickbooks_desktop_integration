module QBWC
  module Request
    class Inventories
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << add_xml_to_send(object, params, session_id)
          end
        end

        def generate_request_queries(objects, params)
          # There is no query
          ''
        end

        def add_xml_to_send(inventory, params, session_id)
          <<-XML
<InventoryAdjustmentAddRq requestID="#{session_id}">
   <InventoryAdjustmentAdd>
    #{inventory_xml(inventory, params)}
   </InventoryAdjustmentAdd>
</InventoryAdjustmentAddRq>
          XML
        end

        def inventory_xml(inventory, params)
          <<-XML
      AccountRef>
        <FullName>#{params['quickbooks_income_account']}</FullName>
      </AccountRef>
      <RefNumber>#{inventory['id']}</RefNumber>
      <InventoryAdjustmentLineAdd>
        <ItemRef>
          <FullName>#{inventory['product_id']}</FullName>
        </ItemRef>
        <QuantityAdjustment>
          <NewQuantity>#{inventory['quantity']}</NewQuantity>
        </QuantityAdjustment>
      </InventoryAdjustmentLineAdd>
      </InventoryAdjustmentAdd>
          XML
        end
      end
    end
  end
end

