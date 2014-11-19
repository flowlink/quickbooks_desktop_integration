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
      receive_settings = s3_settings.settings 'get_'
      params = config.merge receive: receive_settings

      Response::All.new(response_xml).process(params)
    end
  end
end
