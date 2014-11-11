module QBWC
  class Producer
    attr_reader :integration, :s3_settings

    def initialize(config = {}, payload = {})
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
      settings.each do |record|
        object_type = record.keys.first
        config = record.values.first

        if config['polling'] || true
          klass = "QBWC::Request::#{object_type.pluralize.capitalize}".constantize
          string << klass.polling_xml(config['quickbooks_since'])
        end
      end

      string
    end

    private
    def settings
      @settings ||= s3_settings.fetch
    end

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
