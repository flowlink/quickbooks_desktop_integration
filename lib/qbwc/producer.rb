module QBWC
  class Producer
    attr_reader :integration, :config, :s3_settings

    def initialize(config = {}, payload = {})
      @config = config.with_indifferent_access
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

      integration.process_two_phase_pending_objects
      request_xml
    end

    def build_polling_request
      s3_settings.settings('get_').inject('') do |string, record|
        object_type = record.keys.first
        params = record.values.first

        # We support get_products and get_inventories but both match
        # ItemInventoryQuery in quickbooks desktop
        klass = QBWC::Request::Inventories
        string << klass.polling_xml(params['quickbooks_since'])
      end
    end

    private

    def process_insert_update(objects_hash)
      send_settings = s3_settings.settings('add_') if objects_hash.any?

      objects_hash.inject('') do |result, object_hash|
        object_type = object_hash.keys.first

        klass = "QBWC::Request::#{object_type.capitalize}".constantize
        records = object_hash.values.flatten

        params = send_settings.find { |s| s[object_type] } || {}
        result << klass.generate_request_insert_update(records, params[object_type] || {})
      end
    end

    def process_queries(objects_hash)
      objects_hash.inject('') do |result, objects|
        object_type = objects.keys.first

        class_name = "QBWC::Request::#{object_type.capitalize}".constantize

        result << class_name.generate_request_queries(objects[object_type], config)
      end
    end
  end
end
