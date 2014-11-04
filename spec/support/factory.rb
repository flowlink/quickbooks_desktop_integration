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
    end
  end
end
