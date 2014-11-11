module QBWC
  class Consumer
    attr_reader :integration

    def initialize(config = {}, payload = {})
      @integration = Persistence::Object.new config, payload
    end

    def digest_response_into_actions(response_xml)
      # Parse and break response to specific objects
      objects = QBWC::Response::All.new(response_xml).process
puts "\n\n *** digest_response_into_actions: #{objects.inspect}"
      # TODO Think another way to find the right objects to the right methods
      objects.each do |request|
        next if request.nil?
        integration.update_objects_files(request[:statuses_objects]) if request.keys.first == 'statuses_objects'
      end

      # We need to create a service to create notifications, here
      #Notifications.create
    end
  end
end
