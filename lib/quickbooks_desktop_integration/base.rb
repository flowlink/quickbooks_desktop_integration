module QuickbooksDesktopIntegration
  class Base
    attr_reader :config, :objects, :payload_key, :amazon_s3

    # +payload+ might have a collection of records when writing to s3
    #
    #   e.g. { orders: [{ id: "123" }, { id: "123" }] }
    # 
    # or just the key when reading from s3
    #
    #   e.g. { orders: {} }
    #
    # +config+ should tell the :origin and the :account_id
    #
    #   e.g. { origin: 'quickbooks', account_id: 'x123' }
    #
    def initialize(config = {}, payload = {})
      @payload_key = payload.keys.first
      @objects = payload[payload_key]
      @config = config
      @amazon_s3 = AmazonS3.new
    end

    # It doesn't check whether the record (s) is already in s3
    #
    # AmazonS3 will append a number to the end of the file. e.g. orders_123123(1)
    # if it already exists.
    #
    #   e.g. wombat_to_be_integrated/x123_orders_1234567.csv
    #   e.g. quickbooks_to_be_integrated/x123_orders_1234567.csv
    #
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
        new_filename = "#{config[:origin]}_#{next_folder}/#{filename}"

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
      "#{config[:account_id]}_#{payload_key}"
    end

    def to_be_integrated
      "#{config[:origin]}_to_be_integrated"
    end

    def current_time
      Time.now.utc.to_i
    end
  end
end
