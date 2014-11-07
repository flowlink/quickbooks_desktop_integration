require 'pry-byebug'
require 'nori'
require 'nokogiri'
require 'fast_xs'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

if File.exists? File.join(File.expand_path(File.dirname(__FILE__)), '.env')
  # TODO check an ENV variable i.e. RACK_ENV
  begin
    require 'dotenv'
    Dotenv.load
  rescue => e
    puts e.message
    puts e.backtrace.join("\n")
  end
end

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

  get '/' do
    'ok'
    # send_request_xml
  end

  post '/' do
    content_type 'text/xml'

    body = request.body.read
    doc = Nokogiri::XML(body)
    # nori = Nori.new
    # hash = nori.parse body

    # poor parser / TODO refactor it
    # => {"soapenv:Envelope"=>
    # {"soapenv:Header"=>nil, "soapenv:Body"=>{"fe5:closeConnection"=>{"fe5:ticket"=>"?"}}, "@xmlns:soapenv"=>"http://schemas.xmlsoap.org/soap/envelope/", "@xmlns:fe5"=>"https://fe533b4.ngrok.com/"}}
    # operation = hash['soap:Envelope']['soap:Body'].keys.first.split(':').last.underscore
    operation = doc.children.first.children.first.children.first.name.underscore

    # server_version
    # client_version
    # authenticate
    # send_request_xml
    # get_last_error
    # close_connection

    puts operation
    # puts body
    puts '*' * 100
    send operation, body
  end

  def server_version(body)
    erb :'qbwc/server_version'
  end


  def client_version(body)
    erb :'qbwc/client_version'
  end

  def authenticate(body)
    body = CGI.unescapeHTML(body)

    body.slice! '<?xml version="1.0" ?>'
    parser = Nori.new :strip_namespaces => true
    envelope = parser.parse body

    response = envelope['Envelope']['Body']['authenticate']

    username = response['strUserName']
    password = response['strPassword']

    require 'digest/sha1'
    expected_password = Digest::SHA1.hexdigest "#{username}#{ENV['QB_PASSWORD_KEY']}"

    if password == expected_password
      @result = '' # valid password - empty to use the current opened company file
    else
      @result = 'nvu' # invalid password - not valid user
    end


    erb :'qbwc/authenticate'
  end

  def connection_error(body)
    erb :'qbwc/connection_error'
  end

  def send_request_xml(body)

    #    Service::RequestProcessor.build_available_actions_to_request

    @qbxml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<?qbxml version="13.0"?>
<QBXML>
   <QBXMLMsgsRq onError="stopOnError">
      <ItemInventoryAddRq>
         <ItemInventoryAdd>
            <Name>SPREE-T-SHIRT-9</Name>
            <SalesDesc>Description SPREE T SHIRT 9</SalesDesc>
            <SalesPrice>1.6</SalesPrice>
            <IncomeAccountRef>
               <FullName>Inventory Asset</FullName>
            </IncomeAccountRef>
            <PurchaseCost>0.5</PurchaseCost>
            <COGSAccountRef>
              <FullName>Inventory Asset</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
               <FullName>Inventory Asset</FullName>
            </AssetAccountRef>
         </ItemInventoryAdd>
      </ItemInventoryAddRq>
   </QBXMLMsgsRq>
</QBXML>
    XML

    erb :'qbwc/send_request_xml'
  end

  def receive_response_xml(body)
    Service::RequestProcessor.new.digest_response_into_actions(body)

    erb :'qbwc/receive_response_xml'
  end

  def get_last_error(body)
    erb :'qbwc/get_last_error'
  end

  def close_connection(body)
    erb :'qbwc/close_connection'
  end
end
