module QBWC
  class Producer
    attr_reader :integration, :config, :s3_settings

    def initialize(config = {}, payload = {})
      @config = config
      @integration = Persistence::Object.new config, payload
      @s3_settings = Persistence::Settings.new config
    end

    # Create a XML Requests that englobe all operations available on this time
    def build_available_actions_to_request
      request_xml = ''

      request_xml << build_polling_request

      # NOTE Wouldn't this take forever depending on how many objects are
      # waiting to be integrated? Verify if we should limit the s3 queries

      # Get Objets are ready
      request_xml << process_insert_update(integration.get_ready_objects_to_send)

      # Get Objects to query
      request_xml << process_queries(integration.process_pending_objects)

      # Get another pending operations...
    end

    def build_polling_request
      string = ''
      s3_settings.settings('get_').each do |record|
        object_type = record.keys.first
        params = record.values.first

        # We support get_products and get_inventories but both match
        # ItemInventoryQuery in quickbooks desktop
        klass = QBWC::Request::Inventories
        string << klass.polling_xml(params['quickbooks_since'])
      end

      string
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
      objects_hash.inject('') do |result, objects|
        object_type = objects.keys.first

        class_name = "QBWC::Request::#{object_type.capitalize}".constantize

        result << class_name.generate_request_queries(objects[object_type])
      end
    end
  end
end
