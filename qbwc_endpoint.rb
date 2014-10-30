require 'pry-byebug'
require 'nori'

class QBWCEndpoint < Sinatra::Base
  set :logging, true

  unless String.respond_to? :underscore
    class String
      def underscore
        self.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end
  end

  post '/' do
    nori = Nori.new

    hash = nori.parse request.body.read

    # poor parser / TODO refactor it
    # => {"soapenv:Envelope"=>
    # {"soapenv:Header"=>nil, "soapenv:Body"=>{"fe5:closeConnection"=>{"fe5:ticket"=>"?"}}, "@xmlns:soapenv"=>"http://schemas.xmlsoap.org/soap/envelope/", "@xmlns:fe5"=>"https://fe533b4.ngrok.com/"}}
    op = hash['soapenv:Envelope']['soapenv:Body'].keys.first.split(':').last.underscore

    send op
  end

  def server_version
    # <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dev="http://developer.intuit.com/">
    # <soap:Header/>
    # <soap:Body>
    # <dev:serverVersion/>
    # </soap:Body>
    # </soap:Envelope>
  end

  def client_version
    # <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dev="http://developer.intuit.com/">
    # <soapenv:Header/>
    # <soapenv:Body>
    # <dev:clientVersion>
    # <!--Optional:-->
    # <dev:strVersion>?</dev:strVersion>
    # </dev:clientVersion>
    # </soapenv:Body>
    # </soapenv:Envelope>
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <soap:Fault>
         <faultcode>soap:Server</faultcode>
         <faultstring>Server was unable to process request. ---> Input string was not in a correct format.</faultstring>
         <detail/>
      </soap:Fault>
   </soap:Body>
</soap:Envelope>'
  end

  def authenticate
    # <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dev="http://developer.intuit.com/">
    # <soapenv:Header/>
    # <soapenv:Body>
    # <dev:authenticate>
    # <!--Optional:-->
    # <dev:strUserName>?</dev:strUserName>
    # <!--Optional:-->
    # <dev:strPassword>?</dev:strPassword>
    # </dev:authenticate>
    # </soapenv:Body>
    # </soapenv:Envelope>
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <authenticateResponse xmlns="http://developer.intuit.com/">
         <authenticateResult>
            <string>354f40b4-b661-4472-a13f-8abf13a743c3</string>
            <string>nvu</string>
            <string xsi:nil="true"/>
            <string xsi:nil="true"/>
         </authenticateResult>
      </authenticateResponse>
   </soap:Body>
</soap:Envelope>'
  end

  def connection_error
    # <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dev="http://developer.intuit.com/">
    # <soap:Header/>
    # <soap:Body>
    # <dev:connectionError>
    # <!--Optional:-->
    # <dev:ticket>?</dev:ticket>
    # <!--Optional:-->
    # <dev:hresult>?</dev:hresult>
    # <!--Optional:-->
    # <dev:message>?</dev:message>
    # </dev:connectionError>
    # </soap:Body>
    # </soap:Envelope>
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <connectionErrorResponse xmlns="http://developer.intuit.com/">
         <connectionErrorResult>c:\Program Files\Intuit\QuickBooks\sample_product-based business.qbw</connectionErrorResult>
      </connectionErrorResponse>
   </soap:Body>
</soap:Envelope>'
  end

  def send_request_xml
    # <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dev="http://developer.intuit.com/">
    # <soap:Header/>
    # <soap:Body>
    # <dev:sendRequestXML>
    # <!--Optional:-->
    # <dev:ticket>?</dev:ticket>
    # <!--Optional:-->
    # <dev:strHCPResponse>?</dev:strHCPResponse>
    # <!--Optional:-->
    # <dev:strCompanyFileName>?</dev:strCompanyFileName>
    # <!--Optional:-->
    # <dev:qbXMLCountry>?</dev:qbXMLCountry>
    # <dev:qbXMLMajorVers>?</dev:qbXMLMajorVers>
    # <dev:qbXMLMinorVers>?</dev:qbXMLMinorVers>
    # </dev:sendRequestXML>
    # </soap:Body>
    # </soap:Envelope>
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <soap:Fault>
         <soap:Code>
            <soap:Value>soap:Sender</soap:Value>
         </soap:Code>
         <soap:Reason>
            <soap:Text xml:lang="en">Server was unable to read request. ---> There is an error in XML document (13, 52). ---> Input string was not in a correct format.</soap:Text>
         </soap:Reason>
         <soap:Detail/>
      </soap:Fault>
   </soap:Body>
</soap:Envelope>'
  end

  def receive_response_xml
    # <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dev="http://developer.intuit.com/">
    # <soap:Header/>
    # <soap:Body>
    # <dev:receiveResponseXML>
    # <!--Optional:-->
    # <dev:ticket>?</dev:ticket>
    # <!--Optional:-->
    # <dev:response>?</dev:response>
    # <!--Optional:-->
    # <dev:hresult>?</dev:hresult>
    # <!--Optional:-->
    # <dev:message>?</dev:message>
    # </dev:receiveResponseXML>
    # </soap:Body>
    # </soap:Envelope>
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <receiveResponseXMLResponse xmlns="http://developer.intuit.com/">
         <receiveResponseXMLResult>-101</receiveResponseXMLResult>
      </receiveResponseXMLResponse>
   </soap:Body>
</soap:Envelope>'
  end

  def get_last_error
    # <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dev="http://developer.intuit.com/">
    # <soap:Header/>
    # <soap:Body>
    # <dev:getLastError>
    # <!--Optional:-->
    # <dev:ticket>?</dev:ticket>
    # </dev:getLastError>
    # </soap:Body>
    # </soap:Envelope>
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <getLastErrorResponse xmlns="http://developer.intuit.com/">
         <getLastErrorResult>Error!</getLastErrorResult>
      </getLastErrorResponse>
   </soap:Body>
</soap:Envelope>'
  end

  def close_connection
    # <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dev="http://developer.intuit.com/">
    # <soapenv:Header/>
    # <soapenv:Body>
    # <dev:closeConnection>
    # <!--Optional:-->
    # <dev:ticket>?</dev:ticket>
    # </dev:closeConnection>
    # </soapenv:Body>
    # </soapenv:Envelope>
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <soap:Body>
      <closeConnectionResponse xmlns="http://developer.intuit.com/">
         <closeConnectionResult>Troubleshoot session ended successfully.</closeConnectionResult>
      </closeConnectionResponse>
   </soap:Body>
</soap:Envelope>'
  end
end
