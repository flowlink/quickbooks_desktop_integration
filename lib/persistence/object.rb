module Persistence
  class Object
    attr_reader :config, :objects, :payload_key, :amazon_s3

    # +payload+ might have a collection of records when writing to s3
    #
    #   e.g. { orders: [{ id: "123" }, { id: "123" }] }
    #
    # or just the key when reading from s3
    #
    #   e.g. { orders: {} }
    #
    # or dont pass any payload if you want to get all data from a specific
    # account.
    #
    # +config+ should tell the :origin and the :connection_id
    #
    #   e.g. { origin: 'quickbooks', connection_id: '54372cb069702d1f59000000' }
    #
    def initialize(config = {}, payload = {})
      @payload_key = payload.keys.first
      @objects = payload[payload_key].is_a?(Hash) ? [payload[payload_key]] : Array(payload[payload_key])
      @config = { origin: 'wombat' }.merge config
      @amazon_s3 = S3Util.new
    end

    def base_name
      "#{config[:connection_id]}"
    end

    def pending
      "#{config[:origin]}_pending"
    end

    def ready
      "#{config[:origin]}_ready"
    end

    def processed
      "#{config[:origin]}_processed"
    end

    def failed
      "#{config[:origin]}_failed"
    end

    # Doesn't check whether the record (s) is already in s3. Only save it.
    #
    # AmazonS3 will append a number to the end of the file. e.g. orders_123123(1)
    # if it already exists.
    #
    # Files MUST be named like this /connectionid/folder/objecttype_object_ref.csv
    #
    #   e.g. 54372cb069702d1f59000000/wombat_pending/orders_T-SHIRT-SPREE1.csv
    #   e.g. 54372cb069702d1f59000000/quickbooks_pending/orders_T-SHIRT-SPREE1.csv
    #
    def save
      objects.each do |object|
        file = "#{base_name}/#{pending}/#{payload_key}_#{object['id']}.csv"
        amazon_s3.export file_name: file, objects: [object]
      end
    end

    # Get object files to query and get ListID and EditSequence
    #
    #   - Fetch files from s3
    #   - Move them to ready folder
    #   - Give it back as a Hash to be created a request
    #   - On Quickbooks callback request response we rename with ListID and EditSequence
    def process_pending_objects
      prefix = "#{base_name}/#{pending}"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum.map do |s3_object|
        connection_id, folder, filename = s3_object.key.split("/")
        object_type, object_ref = filename.split("_")

        contents = s3_object.read

        s3_object.move_to("#{base_name}/#{ready}/#{filename}")

        # return the content of file to create the requests
        { object_type => { object_ref => Converter.csv_to_hash(contents) } }
      end.flatten
    end

    # Rename files with ListID and EditSequence in ready folder
    # objects_to_be_renamed = [ { :object_type => 'product'
    #                             :object_ref => 'T-SHIRT-SPREE-1',
    #                             :list_id => '800000-88888',
    #                             :edit_sequence => '12312312321'} ]
    def update_objects_with_query_results(objects_to_be_renamed)
      objects_to_be_renamed.each do |object|
        filename     = "#{base_name}/#{ready}/#{object[:object_type].pluralize}_#{object[:object_ref]}"
        s3_object    = amazon_s3.bucket.objects["#{filename}.csv"]
        s3_object.move_to("#{filename}_#{object[:edit_sequence]}_#{object[:list_id]}.csv")
      end
    end

    # Get objects from ready folder to insert/update on quickbooks
    # return type sample:
    # [ { 'products' =>  {
    #       :list_id => '111',
    #       :edit_sequence => '22222',
    #       ....
    #      },
    #     'orders' => {
    #       :list_id => '111',
    #       :edit_sequence => '22222',
    #       ....
    #     }
    #   }]
    def get_ready_objects_to_send
      prefix = "#{base_name}/#{ready}"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum.map do |s3_object|
        connection_id, folder, filename = s3_object.key.split("/")
        object_type, object_ref, edit_sequence, list_id = filename.split("_")

        contents = s3_object.read

        { object_type.pluralize =>
          { object_ref =>
            { :list_id => list_id, :edit_sequence => edit_sequence }.
                                           merge(Converter.csv_to_hash(contents).first)
          }
        }
      end.flatten
    end

    # Move files from `ready` folder to `processed` or `failed` accordingly
    # statuses_objects look like this:
    # { :processed => [
    #     { 'products' =>  {
    #         :list_id => '111',
    #         :edit_sequence => '22222',
    #         ....
    #        },
    #       'orders' => {
    #         :list_id => '111',
    #         :edit_sequence => '22222',
    #         ....
    #       }
    #     }
    #   ],
    #   :failed => [] }
    def update_objects_files(statuses_objects)
      statuses_objects.keys.each do |status_key|
        statuses_objects[status_key].each do |types|
          types.keys.each do |object_type|
            types[object_type].each do |object|
              filename = "#{base_name}/#{ready}/#{object[:object_type]}_#{object[:object_ref]}"
              filename << "_#{object[:edit_sequence]}_#{object[:list_id]}" if types[:object_type][:list_id].present?

              s3_object = amazon_s3.bucket.objects["#{filename}.csv"]
              status_folder = send status_key
              new_filename = "#{base_name}/#{status_folder}/#{object[:object_type]}_#{object[:object_ref]}"
              new_filename << "_#{object[:edit_sequence]}_#{object[:list_id]}" if types[:object_type][:list_id].present?

              s3_object.move_to("#{new_filename}.csv")
            end
          end
        end
      end
    end
  end
end
