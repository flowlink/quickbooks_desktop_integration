module Persistence
  # Deal with save and load sessions to know what was sent to process
  class Session
    attr_reader :amazon_s3, :path

    def initialize(config = {})
      @config      = { origin: 'flowlink' }.merge(config).with_indifferent_access
      @amazon_s3   = S3Util.new
      @path        = Persistence::Path.new(@config)
    end

    class << self
      def load(config, session_id)
        Persistence::Session.new(config).load_session(session_id)
      end

      def save(config, object, extra = nil)
        Persistence::Session.new(config).save_session(object, extra)
      end
    end

    def save_session(object, extra = nil)
      session_id = SecureRandom.uuid
      session_id = "#{extra}#{session_id}" if extra
      file = "#{@path.base_name}/#{@path.sessions}/#{session_id}.csv"
      amazon_s3.export file_name: file, objects: [object]
      session_id
    end

    def load_session(session_id)
      file = "#{path.base_name}/#{path.sessions}/#{session_id}.csv"
      contents = ''
      begin
        contents = amazon_s3.convert_download('csv', amazon_s3.bucket.object(file).get.body.read)
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[load_session]: #{file}"
      end

      contents.first unless contents.empty?
    end
  end
end
