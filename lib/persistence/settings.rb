module Persistence
  class Settings
    attr_reader :amazon_s3, :connection_id, :config, :flow, :force_save

    def initialize(config = {})
      @amazon_s3 = S3Util.new

      @config = config
      @connection_id = config[:connection_id]
      @flow = config[:flow]
      @force_save = config[:quickbooks_force_config].to_s == '1' ||
                    config[:quickbooks_force_config].to_s == 'true'
    end

    # Files MUST be named like this /connectionid/settings/flow.csv
    #
    #   e.g. 54372cb069702d1f59000000/settings/receive_product.csv
    #
    def setup
      file = "#{base_name}/#{flow}.csv"
      s3_object = amazon_s3.bucket.object(file)

      if !s3_object.exists? || force_save
        amazon_s3.export file_name: file, objects: [config], override: true
      end
      generate_extra_flows if %w(add_orders add_shipments add_invoices add_salesreceipts).include?(flow)
    end

    def generate_extra_flows
      config_aux = config.dup
      %w(add_products add_customers).each do |extra_flow|
        config_aux['flow'] = extra_flow
        file = "#{base_name}/#{extra_flow}.csv"
        s3_object = amazon_s3.bucket.object(file)

        if !s3_object.exists? || force_save
          amazon_s3.export file_name: file, objects: [config_aux], override: true
        end
      end
    end

    def fetch(prefix = nil)
      prefix = "#{base_name}/#{prefix}"
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.map do |s3_object|
        connection_id, folder, filename = s3_object.key.split('/')
        flow, extension = filename.split('.')
        object_type = flow.split('_').last.pluralize

        contents = s3_object.get.body.read

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

    def settings(prefix)
      @settings ||= {}
      @settings[prefix] ||= fetch prefix
    end
  end
end
