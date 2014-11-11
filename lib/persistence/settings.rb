module Persistence
  class Settings
    attr_reader :amazon_s3, :connection_id, :config, :object_type, :force_save

    def initialize(config = {})
      @amazon_s3 = S3Util.new

      @config = config
      @connection_id = config[:connection_id]

      @object_type = config[:quickbooks_object_type]

      @force_save = config[:quickbooks_force_config].to_s == "1" ||
        config[:quickbooks_force_config].to_s == "true"
    end

    # Files MUST be named like this /connectionid/settings.csv
    #
    #   e.g. 54372cb069702d1f59000000/settings/product.csv
    #
    def setup
      file = "#{base_name}/#{object_type}.csv"
      s3_object = amazon_s3.bucket.objects[file]

      if !s3_object.exists? || force_save
        amazon_s3.export file_name: file, objects: [config], override: true
      end
    end

    def fetch
      collection = amazon_s3.bucket.objects

      collection.with_prefix(base_name).enum.map do |s3_object|
        connection_id, folder, filename = s3_object.key.split("/")
        object_type, extension = filename.split(".")

        contents = s3_object.read

        # [
        #   {
        #     "connection_id"=>"54591b3a5869632afc090000",
        #     "origin"=>"quickbooks",
        #     "quickbooks_object_type"=>"inventory",
        #     "quickbooks_since"=>"2014-11-10T09:10:55Z",
        #     "quickbooks_force_config"=>"0"
        #   }
        # ]
        data = Converter.csv_to_hash(contents)
        configs = data.first

        { object_type => configs }
      end.flatten
    end

    def base_name
      "#{connection_id}/settings"
    end
  end
end
