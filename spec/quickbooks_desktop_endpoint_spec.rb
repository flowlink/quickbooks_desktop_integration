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

  it "save callback response as notifications to s3" do
    request = {
      "connection_id" => "x123",
      "some_kind_of_reference" => "Status code or a message for succcesfull / failure"
    }

    VCR.use_cassette "requests/1414681635" do
      post "/qb_response_callback", request.to_json
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200
    end
  end
end
