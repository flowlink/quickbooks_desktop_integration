require 'spec_helper'
require 'pp'

describe QuickbooksDesktopEndpoint do
  it 'sends product to be persisted in s3' do
    headers = auth.merge('HTTP_X_HUB_STORE' => '54591b3a5869632afc090000')
    request = {
      'product' => Factory.product_single,
      'parameters' => {
        'quickbooks_income_account'    => 'Inventory Asset',
        'quickbooks_cogs_account'      => 'Inventory Asset',
        'quickbooks_inventory_account' => 'Inventory Asset',
        'payload_type'      => 'products'
      }
    }

    VCR.use_cassette 'products/32425454354353' do
      post '/add_products', request.to_json, headers
      expect(last_response.status).to be 200
      expect(body['summary']).to eq 'Products waiting for Quickbooks Desktop scheduler'
    end
  end

  # keeping this here just as a suggestion, this endpoint will live in qbwc_endoint
  #
  # it "save callback response as notifications to s3" do
  #   request = {
  #     "connection_id" => "x123",
  #     "response" => [
  #       {
  #         "result" => "fail",
  #         "object_ref" => "1414728530",
  #         "summary" => "1414728530 object notification yay message"
  #       }
  #     ]
  #   }

  #   VCR.use_cassette "requests/1414728530" do
  #     post "/qb_response_callback", request.to_json
  #     expect(json_response[:summary]).to eq nil
  #     expect(last_response.status).to eq 200
  #   end
  # end

  # it "returns notifications in batch format" do
  #   headers = auth.merge("HTTP_X_HUB_STORE" => "x123")

  #   request = {
  #     parameters: {
  #       object_type: "products"
  #     }
  #   }

  #   VCR.use_cassette "requests/get_notifications" do
  #     post "/get_notifications", request.to_json, headers

  #     expect(json_response[:summary]).to eq nil
  #     expect(last_response.status).to eq 200
  #     puts last_response.inspect
  #   end
  # end

  it 'gets inventories from quickbooks' do
    headers = auth.merge('HTTP_X_HUB_STORE' => '54591b3a5869632afc090000')
    request = {
      parameters: {
        quickbooks_since: '2014-11-10T09:10:55Z',
        quickbooks_force_config: 0
      }
    }

    VCR.use_cassette 'requests/425435435234532' do
      post '/get_inventories', request.to_json, headers

      expect(json_response[:summary]).to match 'records from quickbooks'
      expect(last_response.status).to eq 200
      expect(json_response[:inventories].count).to be >= 1

      params = json_response[:parameters]
      expect(params).to have_key 'quickbooks_since'
      expect(params['quickbooks_force_config']).to eq false
    end
  end

  it 'gets no inventories' do
    headers = auth.merge('HTTP_X_HUB_STORE' => '54591b3a5869632afc090000')

    VCR.use_cassette 'requests/43535345325' do
      post '/get_inventories', {}.to_json, headers
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200

      params = json_response[:parameters]
      expect(params['quickbooks_force_config']).to eq false
    end
  end

  it 'gets products from quickbooks' do
    headers = auth.merge('HTTP_X_HUB_STORE' => '54591b3a5869632afc090000')
    request = {
      parameters: {
        quickbooks_since: '2014-11-01T09:10:55Z',
        quickbooks_force_config: 0
      }
    }

    VCR.use_cassette 'requests/4253442355352' do
      post '/get_products', request.to_json, headers

      expect(json_response[:summary]).to match 'records from quickbooks'
      expect(last_response.status).to eq 200
      expect(json_response[:products].count).to be >= 1

      params = json_response[:parameters]
      expect(params).to have_key 'quickbooks_since'
      expect(params['quickbooks_force_config']).to eq false
    end
  end
end
