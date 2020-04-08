module QBWC
  class Consumer
    attr_reader :integration, :config, :payload, :s3_settings

    def initialize(config = {}, payload = {})
      @config = config
      @payload = payload
      @integration = Persistence::Object.new(config, payload)
      @s3_settings = Persistence::Settings.new(config)
    end

    def digest_response_into_actions(response_xml)
      receive_settings = s3_settings.settings('get_')
      params = config.merge receive: receive_settings

      send_settings = s3_settings.settings('add_')
      %w(orders shipments invoices customers purchaseorders).each do |object_type|
        send_params = send_settings.find { |s| s[object_type] } || {}
        params = params.merge(send_params[object_type]) if send_params.key?(object_type)
      end
      puts "=" * 99
      puts "Consumer#digest_response_into_actions"
      puts "params"
      puts params.inspect
      puts "response_xml"
      puts response_xml.inspect
      puts "=" * 99
      Response::All.new(response_xml).process(params)
    rescue  Exception => e
      puts "Exception: digest_response_into_actions: message:#{e.message} backtrace:#{e.backtrace.inspect}"
    end
  end
end
