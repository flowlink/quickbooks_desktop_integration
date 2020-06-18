require 'spec_helper'
require 'pp'

describe QBWCEndpoint do
  let(:connection_id) { 'nurelmremote' }
  let(:password) { ENV['QBWC_PASSWORD'] }
  it 'get /:connection_id' do
    get "/#{connection_id}"
    expect(last_response.status).to be 200
  end

  it 'get /support' do
    get '/support'
    expect(last_response.status).to be 302
  end

  context 'post /:connection_id' do
    it 'clientVersion' do
      headers = {}
      request = <<~XML
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <clientVersion xmlns="http://developer.intuit.com/">
      <strVersion>#{connection_id}</strVersion>
    </clientVersion>
  </soap:Body>
</soap:Envelope>
      XML

      post "#{connection_id}", request, headers

      expect(last_response.status).to be 200
      expect(last_response.body).to match 'clientVersionResult'
    end

    it 'serverVersion' do
      headers = {}
      request = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <authenticate xmlns="http://developer.intuit.com/">
      <strUserName>#{connection_id}</strUserName>
      <strPassword>#{password}</strPassword>
    </authenticate>
  </soap:Body>
</soap:Envelope>
      XML

      post "#{connection_id}", request, headers

      expect(last_response.status).to be 200
      expect(last_response.body).to match 'authenticateResult'
    end
  end
end
