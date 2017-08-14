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
      begin
        request_xml << build_polling_request

        # NOTE Wouldn't this take forever depending on how many objects are
        # waiting to be integrated? Verify if we should limit the s3 queries

        # Get Objets are ready
        request_xml << process_insert_update(integration.get_ready_objects_to_send)

        # Get Objects to query
        request_xml << process_queries(integration.process_pending_objects)

        integration.process_two_phase_pending_objects
      rescue  Exception => e
        puts "Exception: build_available_actions_to_request: #{e.message} #{e.backtrace.inspect}"
      end
      request_xml
    end

    def build_polling_request
      s3_settings.settings('get_').inject('') do |string, record|
        object_type = record.keys.first
        params = record.values.first

        klass = "QBWC::Request::#{object_type.capitalize}".constantize
        string << klass.polling_others_items_xml(params['quickbooks_since'], @config)
        string << klass.polling_current_items_xml(params['quickbooks_since'], @config)
      end
    end

    private

    def process_insert_update(objects_hash)
      objects_hash.inject('') do |result, object_hash|
        object_type = object_hash.keys.first

        klass = "QBWC::Request::#{object_type.capitalize}".constantize
        records = object_hash.values.flatten
        result << klass.generate_request_insert_update(
          records,
          config.merge(add_flows_params(object_type) || {})
        )
      end
    end

    def add_flows_params(object_type)
      send_settings = s3_settings.settings('add_') if object_type.pluralize != 'inventories'
      send_settings = s3_settings.settings('set_') if object_type.pluralize == 'inventories'

      object_type = 'products' if object_type == 'adjustments'
      object_type = 'shipments' if object_type == 'payments'
      params = send_settings.find { |s| s[object_type] } || {}
      params[object_type]
    end

    def process_queries(objects_hash)
      objects_hash.inject('') do |result, objects|
        object_type = objects.keys.first

        class_name = "QBWC::Request::#{object_type.capitalize}".constantize

        result << class_name.generate_request_queries(objects[object_type], @config)
      end
    end
  end
end
