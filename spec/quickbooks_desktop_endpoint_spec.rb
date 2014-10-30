require 'spec_helper'

describe QuickbooksDesktopEndpoint do
  it "send orders to s3" do
    request = Factory.orders
    headers = auth.merge("HTTP_X_HUB_STORE" => "x123")

    VCR.use_cassette "add_orders/1414614344" do
      post "add_orders", request.to_json, headers
      expect(json_response[:summary]).to match "waiting for"
      expect(last_response.status).to be 200
    end
  end
end
