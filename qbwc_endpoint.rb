require 'pry-byebug'
require 'nori'
require 'nokogiri'
require 'fast_xs'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

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
    erb :'qbwc/authenticate'
  end

  def connection_error(body)
    erb :'qbwc/connection_error'
  end

  def send_request_xml(body)
    @qbxml = <<-XML
<?xml version="1.0" ?>
<?qbxml version="5.0" ?>
<QBXML>
  <QBXMLMsgsRq onError="continueOnError">
    <ItemInventoryQueryRq requestID="1">
      <MaxReturned>50</MaxReturned>
      <!-- <IncludeRetElement>Name</IncludeRetElement> -->
    </ItemInventoryQueryRq>
  </QBXMLMsgsRq>
</QBXML>
XML
    erb :'qbwc/send_request_xml'
  end

  def receive_response_xml(body)
    puts body = CGI.unescapeHTML(body)

    # NOTE Make it generic. Probably figure the operation name,
    # e.g. ItemInventoryQueryRs, and decide from there what to do
    # inventory = QuickbooksDesktopIntegration::Inventory.new body
    # if inventory.records.any?
      # config = { origin: 'quickbooks', account_id: 'x123' }
      # payload = { inventories: inventory.mapped_records }

      # integration = QuickbooksDesktopIntegration::Base.new config, payload
      # s3_object = integration.save_to_s3

      # logger.info "File #{s3_object.key} persisted on s3"
    # else
      # logger.info "Nothing to persist on s3"
    # end

    product = QuickbooksDesktopIntegration::ProductQuery.new body
    erb :'qbwc/receive_response_xml'
  end

  def get_last_error(body)
    erb :'qbwc/get_last_error'
  end

  def close_connection(body)
    erb :'qbwc/close_connection'
  end
end
