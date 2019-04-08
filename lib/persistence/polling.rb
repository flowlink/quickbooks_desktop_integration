module Persistence
  # Responsible for polling tasks
  class Polling
    attr_reader :objects, :payload_key, :amazon_s3, :path

    def initialize(config = {}, payload = {}, payload_key_override = nil)
      @payload_key = payload_key_override || payload.keys.first
      @objects     = if payload.with_indifferent_access[payload_key].is_a?(Hash)
                       [payload.with_indifferent_access[payload_key]]
                     else
                       Array(payload.with_indifferent_access[payload_key])
                     end
      @config      = { origin: 'flowlink' }.merge(config).with_indifferent_access
      @amazon_s3   = S3Util.new
      @path        = Persistence::Path.new(@config)
    end

    def save_for_polling
      polling_path = @config[:origin] == 'quickbooks' ? path.qb_pending : path.pending
      file = "#{path.base_name}/#{polling_path}/#{payload_key}_#{current_time}.json"
      amazon_s3.export file_name: file, objects: objects
    end

    def save_for_query_later
      file = "#{path.base_name}/#{path.pending}/query_#{payload_key}_#{current_time}.json"
      amazon_s3.export file_name: file, objects: objects
    end

    def process_waiting_records
      prefix = "#{path.base_name}/#{path.qb_pending}/#{payload_key}_"
      begin
        collection = amazon_s3.bucket.objects(prefix: prefix)
        collection.map do |s3_object|
          _, _, filename = s3_object.key.split('/')
          object_type    = filename.split('_').first

          content = amazon_s3.convert_download('json', s3_object.get.body.read)

          s3_object.move_to("#{path.base_name_w_bucket}/#{path.processed}/#{filename}")

          # return the content of file to create the requests
          { object_type => content }
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

        content = amazon_s3.convert_download('json', s3_object.get.body.read)

        s3_object.move_to("#{path.base_name_w_bucket}/#{path.processed}/#{filename}")

        # return the content of file to create the requests
        { object_type => content }
      end
    end

    private

    def current_time
      Time.now.to_i
    end
  end
end
