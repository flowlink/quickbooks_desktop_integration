module QuickbooksDesktopIntegration
  class Base
    attr_reader :config, :objects, :payload_key, :amazon_s3

    # +objects+ has to be an array of hashes
    #
    #   e.g. [{ id: "123" }, { id: "123" }]
    #
    def initialize(config = nil, payload = {})
      @payload_key = payload.keys.first
      @objects = payload[payload_key]
      @config = config
      @amazon_s3 = AmazonS3.new
    end

    # NOTE It doesn't check whether the record is already in s3
    #
    # NOTE In case we dont send in batches perhaps we could append the
    # object.id on the file name
    #
    # AmazonS3 will append a number to the end of the file. e.g. orders_123123(1)
    # if it already exists.
    def save_to_s3
      file = "#{to_be_integrated}/#{base_name}_#{current_time}.csv"
      amazon_s3.export file_name: file, objects: objects
    end

    # NOTE Figure a better ruby dsl for this flow:
    #
    #   - Fetch files from s3
    #   - Move them to processing folder
    #   - Give it back as a Hash to be consumed by Quickbooks Desktop
    #   - On Quickbooks callback request response we move these to a integrated/
    # folder. Not sure yet how this synchronization will work though ..
    #
    # NOTE Do in batch? every 20? Moving one by one will be a quite expensive
    # operation
    #
    # NOTE Figure ordering, older files should come first
    #
    # # NOTE Route folder strings through some kind of method to validate
    # so only to_be_integrated / processing / integrated are allowed?
    #
    # NOTE Rescue and move file back if an exception happens
    #
    # Return a collection array of records
    def start_processing(next_folder = "processing")
      prefix = "#{to_be_integrated}/#{base_name}"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum(limit: 10).map do |s3_object|
        folder, filename = s3_object.key.split("/")
        new_filename = "#{next_folder}/#{filename}"

        contents = s3_object.read

        next_s3_object = amazon_s3.find_next_s3_object new_filename
        next_s3_object.write contents

        # NOTE Consider deleting all objects at once, makes it faster
        s3_object.delete

        # NOTE handles the data build xml and send to quickbooks
        Converter.csv_to_hash(contents)
      end.flatten
    end

    def base_name
      "#{config[:connection_id]}_#{payload_key}"
    end

    def to_be_integrated
      "to_be_integrated"
    end

    def current_time
      Time.now.utc.to_i
    end
  end
end
