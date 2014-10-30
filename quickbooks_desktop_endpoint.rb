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

  # Quickbooks will hit this endpoint to tell us about the last object batch
  #
  # POST or GET?
  #
  # NOTE Need to figure how exactly this request will look like.
  # Assume we get a message with some kind of reference to the last
  # file (object or batch of objects) sent a status and or a successful or
  # error message
  post "/qb_response_callback" do
    config = { connection_id: @payload[:connection_id] }
    # NOTE Perhaps add the object type to the key as well
    payload = { notifications: @payload }

    integration = QuickbooksDesktopIntegration::Base.new config, payload
    integration.save_to_s3
    result 200
  end
end
