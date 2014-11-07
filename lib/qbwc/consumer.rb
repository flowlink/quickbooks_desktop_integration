module QBWC
  class Consumer
    attr_reader :integration

    def initialize(config = {}, payload = {})
      @integration = Persistence::Object.new config, payload
    end

    def digest_response_into_actions(response_xml)
      # Parse and break response to specific objects
      objects = QBWC::Response::All.new(response_xml).process

      # Get all objects parsed and transform to these operations:
      # objects_to_be_renamed = [ { :object_type => 'product'
      #                             :object_ref => 'T-SHIRT-SPREE-1',
      #                             :list_id => '800000-88888',
      #                             :edit_sequence => '12312312321'} ]
      integration.update_objects_with_query_results(objects)

      # { :processed => [
      #     { 'products' =>  {
      #         :list_id => '111',
      #         :edit_sequence => '22222',
      #         ....
      #        },
      #       'orders' => {
      #         :list_id => '111',
      #         :edit_sequence => '22222',
      #         ....
      #       }
      #     }
      #   ],
      #   :failed => [] }
      integration.update_objects_files(objects)

      #Notifications.create
    end
  end
end
