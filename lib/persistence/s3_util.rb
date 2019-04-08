require_relative '../converter'
require 'aws-sdk'
module Persistence
  class S3Util
    attr_reader :s3_client

    def initialize(s3_client: nil)
      @s3_client = s3_client || Aws::S3::Resource.new
      @bucket_name = Persistence::Path.new({}).bucket_name
    end

    def export(file_name: nil, objects: nil, override: false)
      verify_bucket!

      if override
        s3_object = bucket.object(file_name)
      else
        s3_object = find_next_s3_object(file_name)
      end

      s3_object.put(body: convert_upload(extension(file_name), objects))
      s3_object
    end

    def import(file_name: nil)
      verify_bucket!

      objects = convert_download(extension(file_name), read_file!(file_name))
      object_count = objects.count

      summary = nil
      summary = "File #{file_name} was read from S3 with #{object_count} object(s)." if object_count > 0

      [summary, objects]
    end

    def find_next_s3_object(file_name)
      s3_object = bucket.object(file_name)
      extension = extension(file_name)

      # file.json exists?
      # save it to file(1).json or file(next_id).json
      #
      # NOTE if you got a long list this will probably take a while to fetch all
      # files with the prefix?
      if s3_object.exists?
        prefix = file_name.gsub(".#{extension}", '(')
        copies = bucket.objects(prefix: prefix).map do |s3_object|
          # extracts the id: already_exists/shipments(2).json -> 2
          s3_object.key.match(/\A.*\((\d+)\)\.#{extension}\z/)[1].to_i
        end

        next_id = copies.max.to_i + 1

        file_name = file_name.gsub(".#{extension}", "(#{next_id}).#{extension}")
        bucket.object(file_name)
      else
        s3_object
      end
    end

    def convert_upload(file_type, objects)
      case file_type.to_s.downcase
      when 'csv'
        Converter.array_of_hashes_to_csv(objects)
      when 'json'
        JSON.generate(objects)
      else
        raise "Please use a valid file type: csv or json. Received: #{file_type}."
      end
    end

    def convert_download(file_type, content)
      case file_type.to_s.downcase
      when 'csv'
        Converter.json_to_hash(content)
      when 'json'
        JSON.parse(content)
      else
        raise "Please use a valid file type: csv or json. Received: #{file_type}."
      end
    end

    def read_file!(file_name)
      s3_object = bucket.objects[file_name]

      if s3_object.exists?
        contents = s3_object.get.body.read
        s3_object.delete
        contents
      else
        ''
      end
    end

    def extension(file_name)
      file_name.split('.').last
    end

    def verify_bucket!
      raise "Bucket '#{@bucket_name}' was not found." unless bucket.exists?
    end

    def bucket
      @s3_client.bucket(@bucket_name)
    end
  end
end
