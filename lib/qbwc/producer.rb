module QBWC
  class Producer
    attr_reader :integration

    def initialize(config = {}, payload = {})
      @integration = Persistence::Object.new config, payload
    end

    # Create a XML Requests that englobe all operations available on this time
    def build_available_actions_to_request
      request_xml = ''

      # Get Objets are ready
      request_xml << process_insert_update(integration.get_ready_objects_to_send)

      # Get Objects to query
      request_xml << process_queries(integration.process_pending_objects)

      # Get another pending operations...

      # Polling operations (receive products and inventories) WIP
      request_xml << QBWC::Request::Inventories.polling_xml
    end

    private

    # TODO Create a way to do this for all objects
    # probably a way to use the keys (products, )
    def process_insert_update(objects_hash)
      objects_hash.inject('') do |result, object_hash|

        object_type = object_hash.keys.first.capitalize

        class_name = "QBWC::Request::#{object_type}".constantize

        result << class_name.generate_request_insert_update(object_hash.values.flatten)
      end
    end

    # TODO Create a way to do this for all objects
    def process_queries(objects_hash)
      objects_hash.inject('') do |result, object_hash|

        object_type = object_hash.keys.first.capitalize

        class_name = "QBWC::Request::#{object_type}".constantize

        result << class_name.generate_request_queries(objects)
      end
    end
  end
end
