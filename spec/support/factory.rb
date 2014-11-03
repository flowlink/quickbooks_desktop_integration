module Factory
  class << self
    Dir.entries("#{File.dirname(__FILE__)}/payloads").each do |file_name|
      next if file_name == '.' or file_name == '..'
      name, ext = file_name.split(".", 2)

      define_method name do
        JSON.parse(IO.read("#{File.dirname(__FILE__)}/payloads/#{name}.json")).with_indifferent_access
      end
    end

    Dir.entries("#{File.dirname(__FILE__)}/qbxml_examples").each do |file_name|
      next if file_name == '.' or file_name == '..'
      name, ext = file_name.split(".", 2)

      define_method "#{name}_qbxml" do
        IO.read("#{File.dirname(__FILE__)}/qbxml_examples/#{name}.xml")
      end
    end
  end
end
