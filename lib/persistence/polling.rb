module Persistence
  # Responsible for polling tasks
  class Polling
    attr_reader :objects, :payload_key, :amazon_s3, :path

    def initialize(config = {}, payload = {})
      @payload_key = payload.keys.first
      @objects     = if payload[payload_key].is_a?(Hash)
                       [payload[payload_key]]
                     else
                       Array(payload[payload_key])
                     end

      @config      = { origin: 'wombat' }.merge(config).with_indifferent_access
      @amazon_s3   = S3Util.new
      @path        = Persistence::Path.new(@config)
    end

    def save_for_polling
      file = "#{path.base_name}/#{path.pending}/#{payload_key}_#{current_time}.csv"
      amazon_s3.export file_name: file, objects: objects
    end

    def save_for_query_later
      file = "#{path.base_name}/#{path.pending}/query_#{payload_key}_#{current_time}.csv"
      amazon_s3.export file_name: file, objects: objects
    end

    def process_waiting_records
      prefix = "#{path.base_name}/#{path.pending}/#{payload_key}_"
      begin
        collection = amazon_s3.bucket.objects(prefix: prefix)
        collection.map do |s3_object|
          _, _, filename = s3_object.key.split('/')
          object_type    = filename.split('_').first

          contents = s3_object.get.body.read

          s3_object.move_to("#{path.base_name}/#{path.processed}/#{filename}")

          # return the content of file to create the requests
          { object_type => Converter.csv_to_hash(contents) }
        end
      rescue Aws::S3::Errors::NoSuchKey
        puts " File not found(process_waiting_records): #{prefix}"
      end
    end

    def process_waiting_query_later_ids
      prefix = "#{path.base_name}/#{path.pending}/query_#{payload_key}_"
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.map do |s3_object|
        _, _, filename = s3_object.key.split('/')
        object_type    = filename.split('_').second

        contents = s3_object.get.body.read

        s3_object.move_to("#{path.base_name}/#{path.processed}/#{filename}")

        # return the content of file to create the requests
        { object_type => Converter.csv_to_hash(contents) }
      end
    end

    private

    def current_time
      Time.now.to_i
    end
  end
end
