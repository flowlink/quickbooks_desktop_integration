module Persistence
  class Settings
    attr_reader :amazon_s3, :connection_id, :config, :object_type, :force_save

    #
    # {
    #   quickbooks_object_type: 'product',
    #   quickbooks_since: Time.now,
    #   quickbooks_force_timestamp: 0
    # }
    #
    def initialize(config = {})
      @amazon_s3 = S3Util.new

      @config = config
      @connection_id = config[:connection_id]

      @object_type = config[:quickbooks_object_type]

      @force_save = config[:quickbooks_force_config].to_s == "1" ||
        config[:quickbooks_force_timestamp].to_s == "true"
    end

    # Files MUST be named like this /connectionid/settings.csv
    #
    #   e.g. 54372cb069702d1f59000000/settings/product.csv
    #
    def setup
      file = "#{connection_id}/settings/#{object_type}.csv"
      s3_object = amazon_s3.bucket.objects[file]

      if !s3_object.exists? || force_save
        amazon_s3.export file_name: file, objects: [config], override: true
      end
    end
  end
end
