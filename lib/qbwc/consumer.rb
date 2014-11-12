module QBWC
  class Consumer
    attr_reader :integration, :config, :payload, :s3_settings

    def initialize(config = {}, payload = {})
      @config      = config
      @payload     = payload
      @integration = Persistence::Object.new config, payload
      @s3_settings = Persistence::Settings.new config
    end

    def digest_response_into_actions(response_xml)
      receive_settings = s3_settings.settings 'receive'
      params = config.merge receive: receive_settings

      # Parse and break response to specific objects
      objects = Response::All.new(response_xml).process(params)

      # TODO Think another way to find the right objects to the right methods
      objects.to_a.compact.each do |request|
        integration.update_objects_files(request[:statuses_objects]) if request['statuses_objects']
      end

      # We need to create a service to create notifications, here
      #Notifications.create
    end
  end
end
