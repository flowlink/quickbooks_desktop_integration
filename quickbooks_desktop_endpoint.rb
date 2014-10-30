class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  ['products', 'orders', 'inventory', 'returns', 'customers'].each do |path|
    post "/add_#{path}" do
      config = @config.merge connection_id: request.env["HTTP_X_HUB_STORE"]
      integration = QuickbooksDesktopIntegration::Base.new config, @payload
      integration.save_to_s3

      object_type = integration.payload_key.capitalize
      result 200, "#{object_type} waiting for Quickbooks Desktop scheduler"
    end
  end
end
