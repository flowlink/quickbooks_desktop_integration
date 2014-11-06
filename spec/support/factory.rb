module Factory
  @@cache = {}

  class << self
    Dir.entries("#{File.dirname(__FILE__)}/payloads").each do |file_name|
      next if file_name.start_with? '.'

      name = file_name.split('.', 2).first

      method_name = name.downcase

      define_method method_name do
        @@cache[method_name] ||= JSON.parse(IO.read("#{File.dirname(__FILE__)}/payloads/#{name}.json")).with_indifferent_access
      end
    end

    Dir.entries("#{File.dirname(__FILE__)}/qbxml_examples").each do |file_name|
      next if file_name.start_with? '.'

      name = file_name.split('.', 2).first

      method_name = "#{name}_qbxml".downcase

      define_method method_name do
        @@cache[method_name] ||= CGI.unescapeHTML(IO.read("#{File.dirname(__FILE__)}/qbxml_examples/#{name}.xml"))
      end

      method_name = "#{name}_hash".downcase

      define_method method_name do
        @@cache[method_name] ||= begin
                                   response_xml = CGI.unescapeHTML(IO.read("#{File.dirname(__FILE__)}/qbxml_examples/#{name}.xml"))

                                   response_xml.slice! '<?xml version="1.0" ?>'

                                   nori = Nori.new strip_namespaces: true

                                   envelope = nori.parse(response_xml)

                                   response = envelope['Envelope']['Body']['receiveResponseXML']['response']

                                   response['QBXML']['QBXMLMsgsRs'].values.map(&:values).flatten.select { |value| value.is_a?(Hash) }
                                 end
      end
    end
  end
end
