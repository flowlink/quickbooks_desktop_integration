module Persistence
  class Object
    SUCCESS_NOTIFICATION_MESSAGE="Object successfully sent to Quickbooks Desktop"

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
      @objects     = payload[payload_key].is_a?(Hash) ? [payload[payload_key]] : Array(payload[payload_key])
      @config      = { origin: 'wombat' }.merge(config).with_indifferent_access
      @amazon_s3   = S3Util.new
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
        next unless valid_object?(object)

        if two_phase?
          file = "#{base_name}/#{two_phase_pending}/#{payload_key.pluralize}_#{id_of_object(object)}_.csv"
          amazon_s3.export file_name: file, objects: [object]
          generate_inserts_for_two_phase(object)
        else
          file = "#{base_name}/#{pending}/#{payload_key.pluralize}_#{id_of_object(object)}_.csv"
          amazon_s3.export file_name: file, objects: [object]
        end
      end
    end

    def save_for_polling
      file = "#{base_name}/#{pending}/#{payload_key}_#{current_time}.csv"
      amazon_s3.export file_name: file, objects: objects
    end

    def process_waiting_records
      prefix = "#{base_name}/#{pending}/#{payload_key}_"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum.map do |s3_object|
        _, _, filename = s3_object.key.split("/")
        object_type    = filename.split("_").first

        contents = s3_object.read

        s3_object.move_to("#{base_name}/#{processed}/#{filename}")

        # return the content of file to create the requests
        { object_type => Converter.csv_to_hash(contents) }
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
        _, _, filename    = s3_object.key.split("/")
        object_type, _, _ = filename.split("_")

        contents = s3_object.read

        s3_object.move_to("#{base_name}/#{ready}/#{filename}")

        # return the content of file to create the requests
        { object_type => Converter.csv_to_hash(contents) }
      end.flatten
    end

    # Moves from two_phase_pending to pending, than will be executed the next time
    def process_two_phase_pending_objects
      prefix = "#{base_name}/#{two_phase_pending}"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum.each do |s3_object|
        _, _, filename    = s3_object.key.split("/")
        object_type, _, _ = filename.split("_")

        contents = s3_object.read

        s3_object.move_to("#{base_name}/#{pending}/#{filename}")

      end
    end

    # Rename files with ListID and EditSequence in ready folder
    # objects_to_be_renamed = [ { :object_type => 'product'
    #                             :object_ref => 'T-SHIRT-SPREE-1',
    #                             :list_id => '800000-88888',
    #                             :edit_sequence => '12312312321'}
    #                             :extra_data => { ... }, ]
    def update_objects_with_query_results(objects_to_be_renamed)
      prefix = "#{base_name}/#{ready}"

      unless amazon_s3.bucket.objects.with_prefix(prefix).first
        puts " No Files to be updated at #{prefix}"
        return
      end

      objects_to_be_renamed.to_a.compact.each do |object|
        filename     = "#{prefix}/#{object[:object_type].pluralize}_#{object[:object_ref]}_"

        # TODO what if the file is not there? we should probably at least
        # rescue / log the exception properly and move on with the others?
        # raises when file is not found:
        #
        #   AWS::S3::Errors::NoSuchKey - No Such Key:
        #
        begin
          s3_object     = amazon_s3.bucket.objects["#{filename}.csv"]
          new_file_name = "#{filename}#{object[:list_id]}_#{object[:edit_sequence]}.csv"
          s3_object.move_to(new_file_name)

          if !object[:extra_data].to_s.empty?
            contents = amazon_s3.bucket.objects[new_file_name].read
            amazon_s3.bucket.objects[new_file_name].delete

            with_extra_data = Converter.csv_to_hash(contents).first.merge(object[:extra_data])
            amazon_s3.export file_name: new_file_name, objects: [with_extra_data]
          end
        rescue AWS::S3::Errors::NoSuchKey => e
          puts " File not found: #{filename}.csv"
        end
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

      collection.with_prefix(prefix).enum.select{ |s3| !s3.key.match(/notification/) }.map do |s3_object|
        _, _, filename                         = s3_object.key.split('/')
        object_type, _, list_id, edit_sequence = filename.split('_')

        list_id.gsub!('.csv', '') unless list_id.nil?
        edit_sequence.gsub!('.csv', '') unless edit_sequence.nil?

        contents = s3_object.read

        { object_type.pluralize =>
            { list_id: list_id, edit_sequence: edit_sequence }.
                                           merge(Converter.csv_to_hash(contents).first).with_indifferent_access
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
      return if statuses_objects.nil?

      statuses_objects.keys.each do |status_key|
        statuses_objects[status_key].each do |types|
          types.keys.each do |object_type|
            object = types[object_type]

            filename = "#{base_name}/#{ready}/#{object_type}_#{object[:id]}_"

            collection = amazon_s3.bucket.objects
            collection.with_prefix(filename).enum.each do |s3_object|
              status_folder = send status_key
              new_filename = "#{base_name}/#{status_folder}/#{object_type}_#{object[:id]}_"
              new_filename << "#{object[:list_id]}_#{object[:edit_sequence]}" unless object[:list_id].to_s.empty?

              s3_object.move_to("#{new_filename}.csv")

              create_notifications("#{new_filename}.csv", status_key)
            end
          end
        end
      end
    end

    def get_notifications
      prefix = "#{base_name}/#{ready}/notification_"
      collection = amazon_s3.bucket.objects

      collection.with_prefix(prefix).enum.select{ |s3| s3.key.match(payload_key) }.inject({ 'processed' => {}, 'failed' => {} }) do |notifications, s3_object|
        _, _, filename              = s3_object.key.split("/")
        _, status, _, object_ref, _ = filename.split("_")
        content = amazon_s3.convert_download('csv',s3_object.read).first

        object_ref = id_for_notifications(content, object_ref)

        if content.has_key?('message')
          notifications[status][content['message']] ||= []
          notifications[status][content['message']] << object_ref
        else
          notifications[status][SUCCESS_NOTIFICATION_MESSAGE] ||= []
          notifications[status][SUCCESS_NOTIFICATION_MESSAGE] << object_ref
        end

        s3_object.move_to("#{base_name}/#{processed}/#{filename}")

        notifications
      end
    end

    def save_session(object)
      session_id = SecureRandom.uuid
      file = "#{base_name}/#{sessions}/#{session_id}.csv"
      amazon_s3.export file_name: file, objects: [object]
      session_id
    end

    def load_session(session_id)
      file = "#{base_name}/#{sessions}/#{session_id}.csv"
      contents = ''
      begin
        contents = amazon_s3.convert_download('csv',amazon_s3.bucket.objects[file].read)
      rescue AWS::S3::Errors::NoSuchKey => e
        puts "File not found: #{file}"
      end

      contents.first unless contents.empty?
    end

    def create_error_notifications(error_context, object_type, request_id)
      session      = load_session(request_id)
      generate_error_notification(error_context.merge({ object: session }), object_type)
      update_objects_files({ processed: [], failed: [{ object_type => session }] }.with_indifferent_access)
    end

    class << self
      def handle_error(config, error_context, object_type, request_id)
        Persistence::Object.new(config, {}).create_error_notifications(error_context, object_type, request_id)
      end
      def update_statuses(config = {}, processed = [], failed = [])
        Persistence::Object.new(config, {}).update_objects_files({ processed: processed, failed: failed }.with_indifferent_access)
      end
    end


    private

    def generate_error_notification(content, object_type)
      new_filename = "#{base_name}/#{ready}/notification_failed_#{object_type}_#{content[:object]['id']}_.csv"
      amazon_s3.export(file_name: new_filename, objects: [content])
    end

    def valid_object?(object)
      if payload_key.pluralize == 'orders'
        if object['id'].size > 11
          generate_error_notification({ context: 'Saving orders',
                                        code: '',
                                        message: 'Could not import to qb the Order ID exceeded the limit of 11',
                                        object: object }, payload_key.pluralize)
          return false
        end
      elsif payload_key.pluralize == 'returns'
        if object['id'].size > 11
          generate_error_notification({ context: 'Saving returns',
                                        code: '',
                                        message: 'Could not import to qb the RMA ID exceeded the limit of 11',
                                        object: object }, payload_key.pluralize)
          return false
        end
      end
      true
    end

    def generate_inserts_for_two_phase(object)
      # TODO Create a better way to choose between types
      if payload_key.pluralize == 'orders'
        customer = QBWC::Request::Orders.build_customer_from_order(object)
        products = QBWC::Request::Orders.build_products_from_order(objects)
        save_pending_file(customer['id'], 'customers', customer)
        products.each do |product|
          save_pending_file(product['id'], 'products', product)
        end
      elsif payload_key.pluralize == 'returns'
        customer = QBWC::Request::Returns.build_customer_from_return(object)
        products = QBWC::Request::Returns.build_products_from_return(objects)
        save_pending_file(customer['id'], 'customers', customer)
        products.each do |product|
          save_pending_file(product['id'], 'products', product)
        end
      end
    end

    def save_pending_file(object_ref, object_type, object)
      amazon_s3.export file_name: "#{base_name}/#{pending}/#{object_type}_#{object_ref}_.csv", objects: [object]
    end

    def two_phase?
      ['orders', 'returns'].include?(payload_key.pluralize)
    end

    def two_phase_pending
      "#{config[:origin]}_two_phase_pending"
    end

    def create_notifications(objects_filename, status)
      _, _, filename = objects_filename.split('/')
      s3_object = amazon_s3.bucket.objects[objects_filename]

      new_filename = "#{base_name}/#{ready}/notification_#{status}_#{filename}"
      s3_object.copy_to(new_filename)
    end

    def sessions
      "#{config[:origin]}_sessions"
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

    def current_time
      Time.now.to_i
    end

    def id_of_object(object)
      key = payload_key.pluralize

      if key == 'inventories'
        object['product_id']
      elsif key == 'customers'
        object['email']
      else
        object['id']
      end
    end

    def id_for_notifications(object, object_ref)
      return object['id']  if payload_key.pluralize == 'customers'
      object_ref
    end
  end
end
