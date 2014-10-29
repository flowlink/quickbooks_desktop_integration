class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  post "/add_orders" do
    config = @config.merge connection_id: request.env["HTTP_X_HUB_STORE"]
    order_integration = QuickbooksDesktopIntegration::Order.new config, @payload
    order_integration.save_to_s3

    result 200, "Orders waiting for Quickbooks Desktop scheduler"
  end
end
