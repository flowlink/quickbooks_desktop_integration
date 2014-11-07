module Service
  class RequestProcessor
    attr_reader :integration

    def initialize(config = {}, payload = {})
      integration = Service::Base.new config, payload
    end

    # Create a XML Requests that englobe all operations available on this time
    def build_available_actions_to_request
      request_xml = ""

      # Get Objets are ready
      request_xml << process_insert_update(integration.get_ready_objects_to_send)

      # Get Objects to query
      request_xml << process_queries(integration.process_pending_objects)

      # Get another pending operations...
    end

    def digest_response_into_actions(response)
      # Parse and break response to specific objects
      objects = QBWC::Response::All.new(body).process

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
    end

    private

    # TODO Create a way to do this for all objects
    # probably a way to use the keys (products, )
    def process_insert_update(objects_hash)
      QuickbooksDesktopIntegration::Product.generate_request_insert_update(objects_hash[:products])
    end

    # TODO Create a way to do this for all objects
    def process_queries(pending_objects_hash)
      QuickbooksDesktopIntegration::Product.generate_request_queries(objects_hash[:products])
    end

  end
end
