module Persistence
  class Object
    attr_reader :config, :objects, :payload_key, :amazon_s3, :path, :request_id

    PLURAL_PRODUCT_OBJECT_TYPES = %w(
      products
      noninventoryproducts
      discountproducts
      inventoryproducts
      salestaxproducts
      serviceproducts
      inventoryassemblyproducts
      otherchargeproducts
    )

    IDS_TO_LOG_S3_OBJ_MOVEMENT = ENV.fetch('IDS_TO_LOG', '').split(',')

    DEFAULT_PENDING_THRESHOLD_MINS = 30
    RETRY_CUTOFF = 3

    class << self
      def handle_error(config, error_context, object_type, request_id)
        Persistence::Object.new(config, {})
          .create_error_notifications(error_context, object_type, request_id)
      end

      def update_statuses(config = {}, processed = [], failed = [])
        
        puts({message: "Updating statuses.", config: config, processed: processed, failed: failed})
        Persistence::Object.new(config, {})
          .update_objects_files({ processed: processed, failed: failed }.with_indifferent_access)
      end
    end
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
      @payload_key = payload[:parameters] ? payload[:parameters][:payload_type] : payload.keys.first
      @objects     = payload[payload_key].is_a?(Hash) ? [payload[payload_key]] : Array(payload[payload_key])
      begin
        @payload_key.gsub!('_','')
      rescue
      end
      @config      = { origin: 'flowlink' }.merge(config).with_indifferent_access
      @amazon_s3   = S3Util.new
      @path        = Persistence::Path.new(@config)
      @request_id  = payload[:request_id]
    end

    # Doesn't check whether the record (s) is already in s3. Only save it.
    #
    # AmazonS3 will append a number to the end of the file.
    # e.g. orders_123123(1)
    # if it already exists.
    #
    # Files MUST be named like this
    # /connectionid/folder/objecttype_object_ref.json
    #
    # e.g. 54372cb069702d1f59000000/flowlink_pending/orders_T-SHIRT-SPREE1.json
    # e.g. 54372cb069702d1f59000000/quickbooks_pending/orders_T-SHIRT-SPREE1.json
    #
    def save
      objects.each do |object|
        object['request_id'] = request_id

        puts "Processing object #{object}"

        if object['id'].size > 11
          object['id'] = object['id'].split(//).last(11).join
        end

        next unless valid_object?(object)
        prepare_objects_before_save(object)

        # If an alternate customer email is specified in flow params (should be order flows only)
        # then update to that email and generic customer billing and shipping info
        if use_customer_email_param?
          object[:email] = @config[:quickbooks_customer_email]
        end

        # Get rid of empty addresses
        unless payload_key == 'journal'
          [:shipping_address, :billing_address].each do |address_type|
            if object[address_type].nil? || object[address_type].empty?
              object[address_type] = generic_address
            end
          end
        end

        if two_phase?
          file = "#{path.base_name}/#{path.two_phase_pending}/#{payload_key.pluralize}_#{id_of_object(object)}_.json"
          amazon_s3.export file_name: file, objects: [object]
          generate_inserts_for_two_phase(object, use_customer_email_param?)
        else
          file = "#{path.base_name}/#{path.pending}/#{payload_key.pluralize}_#{id_of_object(object)}_.json"
          amazon_s3.export file_name: file, objects: [object]
        end
        generate_extra_objects(object)
      end
    end

    # Get object files to query and get ListID and EditSequence
    #
    #   - Fetch files from s3
    #   - Move them to ready folder
    #   - Give it back as a Hash to be created a request
    #   - On Quickbooks callback request response we rename
    #    with ListID and EditSequence
    def process_pending_objects
      prefix = "#{path.base_name}/#{path.pending}"
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.map do |s3_object|
        _, _, filename    = s3_object.key.split('/')
        object_type, _, _ = filename.split('_')

        content = amazon_s3.convert_download('json', s3_object.get.body.read).first
        s3_object.move_to("#{path.base_name_w_bucket}/#{path.ready}/#{filename}")

        # return the content of file to create the requests
        { object_type => content }
      end.flatten
    end

    # Moves from two_phase_pending to pending, than will
    # be executed the next time
    def process_two_phase_pending_objects
      prefix = "#{path.base_name}/#{path.two_phase_pending}"
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.each do |s3_object|
        _, _, filename    = s3_object.key.split('/')
        object_type, _, _ = filename.split('_')

        contents = s3_object.get.body.read

        s3_object.move_to("#{path.base_name_w_bucket}/#{path.pending}/#{filename}")
      end
    end

    # Rename files with ListID and EditSequence in ready folder
    # objects_to_be_renamed = [ { :object_type => 'product'
    #                             :object_ref => 'T-SHIRT-SPREE-1',
    #                             :list_id => '800000-88888',
    #                             :edit_sequence => '12312312321'}
    #                             :extra_data => { ... }, ]
    def update_objects_with_query_results(objects_to_be_renamed)
      should_log = should_log_s3_obj_movement?(@config[:connection_id])
      puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", objects_to_be_renamed: objects_to_be_renamed}) if should_log

      prefix = path.base_and_ready
      prefix_with_bucket = path.base_and_bucket_with_ready

      puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", prefix: prefix, prefix_with_bucket: prefix_with_bucket}) if should_log

      objects_to_be_renamed.to_a.compact.each do |object|
        filename     = "#{prefix}/#{type_and_identifier_filename(object, object[:list_id])}"
        filename_with_bucket = "#{prefix_with_bucket}/#{type_and_identifier_filename(object, object[:list_id])}"
        s3_object = amazon_s3.bucket.object("#{filename}.json")
        puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", message: "First try using list_id as filename", object: object, filename: filename, filename_with_bucket: filename_with_bucket}) if should_log

        unless s3_object.exists?
          filename = "#{prefix}/#{type_and_identifier_filename(object, object[:object_ref])}"
          filename_with_bucket = "#{prefix_with_bucket}/#{type_and_identifier_filename(object, object[:object_ref])}"
          s3_object = amazon_s3.bucket.object("#{filename}.json")
          puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", message: "Second try using identifier/object_ref as filename", object: object, filename: filename, filename_with_bucket: filename_with_bucket}) if should_log
        end

        new_file_name = "#{filename}#{list_id_and_edit_sequence(object)}.json"
        new_file_name_with_bucket = "#{filename_with_bucket}#{list_id_and_edit_sequence(object)}.json"

        puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", object: object, filename: new_file_name, filename_w_bucket: new_file_name_with_bucket}) if should_log
        begin
          s3_object.move_to(new_file_name_with_bucket)
          unless object[:extra_data].to_s.empty?
            contents = amazon_s3.bucket.object(new_file_name).get.body.read
            amazon_s3.bucket.object(new_file_name).delete

            with_extra_data = amazon_s3.convert_download('json', contents).first.merge(object[:extra_data])
            puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", current_object_contents: contents, new_data: with_extra_data}) if should_log
            amazon_s3.export file_name: new_file_name, objects: [with_extra_data]
          end
        rescue Aws::S3::Errors::NoSuchKey => e
          puts({connection_id: config[:connection_id], method: "update_objects_with_query_results", object: object, error: e.inspect, backtrace: e.backtrace})
          next
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
      prefix = path.base_and_ready
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.reject { |s3| s3.key.match(/notification/) }.map do |s3_object|
        _, _, filename                         = s3_object.key.split('/')
        object_type, _, list_id, edit_sequence = filename.split('_')
        puts({connection_id: @config[:connection_id], method: "get_ready_objects_to_send", filename: filename, object_type: object_type, list_id: list_id, edit_sequence: edit_sequence})

        list_id.gsub!('.json', '') unless list_id.nil?
        edit_sequence.gsub!('.json', '') unless edit_sequence.nil?
        list_id = nil if edit_sequence.nil? # To fix a problem with multiple files with (n) on it

        object = { object_type.pluralize =>
              amazon_s3.convert_download('json', s3_object.get.body.read).first
              .merge({ list_id: list_id, edit_sequence: edit_sequence, object_type: object_type })
              .with_indifferent_access
        }

        s3_object.move_to("#{path.base_name_w_bucket}/#{path.in_progress}/#{filename}")

        object
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
      should_log = should_log_s3_obj_movement?(@config[:connection_id])
      # puts "Status objects to be processed: #{statuses_objects}"

      puts({connection_id: @config[:connection_id], method: "update_objects_files", statuses_objects: statuses_objects}) if should_log

      return if statuses_objects.nil?

      statuses_objects.keys.each do |status_key|
        # puts status_key
        statuses_objects[status_key].each do |types|
          # puts types
          types.keys.each do |object_type|
            puts({connection_id: @config[:connection_id], method: "update_objects_files", message: "Processing objects", object_type: object_type}) if should_log
            # puts object_type
            # NOTE seeing an nil `object` var here sometimes, investigate it
            # happens when you have both add_orders and get_products flows enabled
            begin
              object = types[object_type].with_indifferent_access 
              identifier = id_for_object(object, object_type)
              filename = "#{path.base_name}/#{path.in_progress}/#{object_type}_#{identifier}_"
              puts({connection_id: @config[:connection_id], method: "update_objects_files", object: object, filename: filename, message: "Filename built and looking in s3 for it"}) if should_log

              collection = amazon_s3.bucket.objects(prefix: filename)
              unless collection.first
                temp_obj = object.clone
                temp_obj.delete("list_id")
                temp_obj.delete(:list_id)
                identifier = id_for_object(temp_obj, object_type)
                filename = "#{path.base_name}/#{path.in_progress}/#{object_type}_#{identifier}_"
                puts({connection_id: @config[:connection_id], method: "update_objects_files", object: object, filename: filename, message: "Filename not found using list_id - trying id_for_object without list_id"}) if should_log
                collection = amazon_s3.bucket.objects(prefix: filename)
              end

              collection.each do |s3_object|
                puts({connection_id: @config[:connection_id], method: "update_objects_files", message: "File found", s3_object: s3_object.inspect}) if should_log
                _, _, ax_filename = s3_object.key.split('/')
                _, _, end_of_file, ax_edit_sequence = ax_filename.split('_')
                end_of_file = '.json' unless ax_edit_sequence.nil?

                puts({connection_id: @config[:connection_id], method: "update_objects_files", message: "Building file parts", ax_filename: ax_filename, end_of_file: end_of_file, ax_edit_sequence: ax_edit_sequence}) if should_log

                status_folder = path.send status_key
                puts({connection_id: @config[:connection_id], method: "update_objects_files", message: "Status Folder", status_folder: status_folder}) if should_log

                new_filename = "#{path.base_name_w_bucket}/#{status_folder}/#{object_type}_#{identifier}_"
                new_filename << "#{object[:list_id]}_#{object[:edit_sequence]}" unless object[:list_id].to_s.empty?

                puts({connection_id: @config[:connection_id], method: "update_objects_files", message:"New filename", new_filename: new_filename, end_of_file: end_of_file}) if should_log

                s3_object.move_to("#{new_filename}#{end_of_file}")

                new_filename_no_bucket = "#{path.base_name}/#{status_folder}/#{object_type}_#{identifier}_"
                new_filename_no_bucket << "#{object[:list_id]}_#{object[:edit_sequence]}" unless object[:list_id].to_s.empty?

                puts({connection_id: @config[:connection_id], method: "update_objects_files", new_filename_no_bucket: new_filename_no_bucket}) if should_log
                create_notifications("#{new_filename_no_bucket}#{end_of_file}", status_key) if status_key == 'processed'
              end
            rescue Exception => e
              puts "Error in update_objects_files: #{statuses_objects} #{e.message} \n\n #{e.backtrace.join('\n')}"
            end
          end
        end
      end
    end

    def get_notifications
      prefix = "#{path.base_name}/#{path.ready}/notification_"
      notification_files = amazon_s3.bucket.objects(prefix: prefix)

      # notification_files = collection.select do |s3|
      #   s3.key.match(payload_key) || (payload_key == 'orders' && s3.key.match('payments'))
      # end

      notification_files.inject('processed' => [], 'failed' => []) do |notifications, s3_object|
        _, _, filename  = s3_object.key.split('/')
        _, status, object_type, _, _ = filename.split('_')
        content = amazon_s3.convert_download('json', s3_object.get.body.read).first
        
        obj = status == 'processed' ? content : content["object"]
        object_ref = id_for_object(obj, object_type)

        if content.key?('message')
          notifications[status] << {
            message: "#{object_ref}: #{content['message']}",
            request_id: content['request_id'] || request_id
          }
        else
          notifications[status] << {
            message: "#{object_ref}: #{success_notification_message(object_type)}",
            request_id: content['request_id'] || request_id
          }
        end

        s3_object.move_to("#{path.base_name_w_bucket}/#{path.processed}/#{filename}")

        notifications
      end
    end

    def create_error_notifications(error_context, object_type, request_id)
      # When there is an error in one request, QB invalidate all other requests, to avoid a lack of objects being processed
      # if the error was this, then the object stay there to process next time
      if error_context[:message] != 'The request has not been processed.'
        session = Persistence::Session.load(config, request_id)
        generate_error_notification(error_context.merge({object: session, request_id: request_id}), object_type)
        update_objects_files({ processed: [], failed: [{ object_type => session }] }.with_indifferent_access)
      end
    end

    # This link invoices and payments
    def update_shipments_with_payment_ids(shipment_id, object)
      file_name = "#{path.base_name}/#{path.pending}/shipments_#{shipment_id}_.json"

      begin
        contents = amazon_s3.convert_download('json', amazon_s3.bucket.object(file_name).get.body.read)
        amazon_s3.bucket.object(file_name).delete
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[update_shipments_with_payment_ids]: #{file_name}"
      end

      contents.first['payment'] = object

      amazon_s3.export file_name: file_name, objects: contents

      begin
        order_file_name = "#{path.base_name}/#{path.ready}/payments_#{object[:object_ref]}_.json"
        amazon_s3.bucket.object(order_file_name).delete
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[delete payments]: #{file_name}"
      end
    end

    # This link Invoices with Sales Orders
    def update_shipments_with_qb_ids(shipment_id, object)
      file_name = "#{path.base_name}/#{path.pending}/shipments_#{shipment_id}_.json"

      begin
        contents = amazon_s3.convert_download('json', amazon_s3.bucket.object(file_name).get.body.read)
        amazon_s3.bucket.object(file_name).delete
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[update_shipments_with_qb_ids]: #{file_name}"
      end

      contents.first['items'] = object[:extra_data]['line_items']
                                .map do |item|
        item['sales_order_txn_line_id'] = item['txn_line_id']
        item['sales_order_txn_id']      = item['txn_id']
        item.delete('txn_line_id')
        item.delete('txn_id')
        item
      end

      contents.first['adjustments'] = object[:extra_data]['adjustments']
                                      .map do |item|
        item['sales_order_txn_line_id'] = item['txn_line_id']
        item['sales_order_txn_id']      = item['txn_id']
        item.delete('txn_line_id')
        item.delete('txn_id')
        item
      end

      amazon_s3.export file_name: file_name, objects: contents

      begin
        order_file_name = "#{path.base_name}/#{path.ready}/orders_#{object[:object_ref]}_.json"
        amazon_s3.bucket.object(order_file_name).delete
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[delete orders]: #{file_name}"
      end
    end

    # Creates payments to updates Invoices IDs into Payments and link one to another,
    # needs to be separated, because we need QB IDs and it's only exists after processed
    def create_payments_updates_from_shipments(_config, shipment_id, invoice_txn_id)
      file_name = "#{path.base_name}/#{path.ready}/shipments_#{shipment_id}_"

      begin
        file = amazon_s3.bucket.objects(prefix: file_name).first

        contents = amazon_s3.convert_download('json', file.get.body.read)
      rescue Aws::S3::Errors::NoSuchKey => _e
        puts "File not found[create_payments_updates_from_shipments]: #{file_name}"
      end
      object = contents.first

      save_object = [{
        'id'              => object['order_id'],
        'invoice_txn_id' => invoice_txn_id,
        'amount'         => object['totals']['payment'],
        'object_ref'     => object['order_id'],
        'list_id'        => object['payment']['list_id'],
        'edit_sequence'  => object['payment']['edit_sequence']
      }]

      new_file_name = "#{path.base_name}/#{path.ready}/payments_#{object['order_id']}_.json"
      amazon_s3.export file_name: new_file_name, objects: save_object
    end

    def retry_in_progress_objects_that_are_stuck
      prefix = "#{path.base_name}/#{path.in_progress}"
      collection = amazon_s3.bucket.objects(prefix: prefix)

      collection.each do |s3_object|
        _, _, filename    = s3_object.key.split('/')
        object_type, identifier, _ = filename.split('_')

        s3_object_json = amazon_s3.convert_download('json', s3_object.get.body.read).first
        next unless should_retry_pending_object?(s3_object_json, s3_object.last_modified)

        # Remove old object and update counter
        amazon_s3.bucket.object(s3_object.key).delete
        s3_object_json['qbe_integration_retry_counter'] = s3_object_json['qbe_integration_retry_counter'].to_i + 1

        @payload_key = object_type # Need to set here => `two_phase?` uses payload_key

        reverted_filename = "#{object_type.pluralize}_#{identifier}_.json"
        destination_folder_name = two_phase? ? path.two_phase_pending : path.pending
        new_version_of_object = amazon_s3.bucket.object("#{path.base_name}/#{destination_folder_name}/#{reverted_filename}.json")

        unless new_version_of_object.exists?
          new_file_name = "#{path.base_name}/#{destination_folder_name}/#{reverted_filename}"
          amazon_s3.export file_name: new_file_name, objects: [s3_object_json]
        else
          # MARCTODO: 
          # Tag this in_progress object with the correct error message?
          # Create a notification maybe to send to FL?
          # "The object failed, but a newer one exists, so we aren't going to retry this one"
        end
      end
    end

    private

    def auto_create_products
      return !@config[:quickbooks_auto_create_products].nil? &&
             !@config[:quickbooks_auto_create_products].empty? &&
              @config[:quickbooks_auto_create_products].to_s == '1'
    end

    def auto_create_payments
      return !@config[:quickbooks_auto_create_payments].nil? &&
             !@config[:quickbooks_auto_create_payments].empty? &&
              @config[:quickbooks_auto_create_payments].to_s == '1'
    end

    def use_customer_object?
      @config[:quickbooks_use_customer_object].to_s == '1'
    end

    def use_vendor_object?
      @config[:quickbooks_use_vendor_object].to_s == '1'
    end

    def use_product_objects?
      @config[:quickbooks_use_product_objects].to_s == '1'
    end

    def success_notification_message(object)
      "#{object.singularize.capitalize} successfully sent to Quickbooks Desktop"
    end

    def generate_error_notification(content, object_type)
      @payload_key = object_type
      if content[:object]
        request_id = content[:request_id].split('_').last
        content[:request_id] = request_id
        new_filename = "#{path.base_name}/#{path.ready}/notification_failed_#{request_id}_#{object_type}_#{id_for_object(content[:object], object_type)}_.json"
        amazon_s3.export(file_name: new_filename, objects: [content])
      else
        puts "generate_error_notification: #{content.inspect}:#{object_type}"
      end
    end

    def create_notifications(objects_filename, status)
      _, _, filename2, filename = objects_filename.split('/')
      filename ||= filename2
      puts({connection_id: @config[:connection_id], method: "create_notifications", objects_filename: objects_filename, filename: filename, filename2: filename2 })
      s3_object = amazon_s3.bucket.object(objects_filename)
      puts({connection_id: @config[:connection_id], method: "create_notifications", s3_object: s3_object})
      
      new_filename = "#{path.base_name_w_bucket}/#{path.ready}/notification_#{status}_#{filename}"
      puts({connection_id: @config[:connection_id], method: "create_notifications", new_filename: new_filename})
      
      s3_object.copy_to(new_filename)
      puts({connection_id: @config[:connection_id], method: "create_notifications", message: "Called s3 create object"})
     
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
      elsif payload_key.pluralize == 'invoices'
        if object['id'].size > 11
          generate_error_notification({ context: 'Saving invoices',
                                        code: '',
                                        message: 'Could not import to qb the Invoice ID exceeded the limit of 11',
                                        object: object }, payload_key.pluralize)
          return false
        end
      elsif payload_key.pluralize == 'purchaseorders'
        if object['id'].size > 11
          generate_error_notification({ context: 'Saving purchase orders',
                                        code: '',
                                        message: 'Could not import to qb the Purchase Order ID exceeded the limit of 11',
                                        object: object }, payload_key.pluralize)
          return false
        end
      elsif payload_key.pluralize == 'salesreceipts'
        if object['id'].size > 11
          generate_error_notification({ context: 'Saving salesreceipts',
                                        code: '',
                                        message: 'Could not import to qb the Sales Receipt ID exceeded the limit of 11',
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

    def prepare_objects_before_save(object)
      object['status'] = 'cancelled' if config['flow'] == 'cancel_order'
    end

    def generic_address
      {
          firstname: 'Generic',
          lastname: 'Customer',
          address1: 'No Address',
          address2: 'No Address',
          zipcode: '12345',
          city: 'No City',
          state: 'Pennsylvania',
          country: 'US',
          phone: '555-555-1212'
      }
    end

    # When inventory is updated, QB doesn't update item inventory,
    # this is to force this update and
    # return to Wombat item inventories updated
    def generate_extra_objects(object)
      # if payload_key.pluralize == 'inventories'
      #   object_aux = object.dup
      #   object_aux['id'] = object_aux['product_id']
      #   object_aux['active'] = true

      #   save_pending_file(object_aux['id'], 'products', object_aux)
      # end
    end

    def generate_inserts_for_two_phase(object, use_customer_email_param)

      if payload_key.pluralize == 'inventories'
        if auto_create_products
          if use_product_objects?
            products = object['products']
          else
            products = QBWC::Request::Orders.build_products_from_order(objects)
          end

          products.flatten.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

        # payments = QBWC::Request::Orders.build_payments_from_order(object)
        # payments.flatten.each do |payment|
        #   save_pending_file(payment['id'], 'payments', payment)
        # end
      elsif payload_key.pluralize == 'orders'

        if !use_customer_email_param
          if use_customer_object?
            customer = object['customer']
          else
            customer = QBWC::Request::Orders.build_customer_from_order(object)
          end
          
          save_pending_file(customer['name'], 'customers', customer)
        end

        if auto_create_products
          if use_product_objects?
            products = object['products']
          else
            products = QBWC::Request::Orders.build_products_from_order(objects)
          end

          products.flatten.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

        # payments = QBWC::Request::Orders.build_payments_from_order(object)
        # payments.flatten.each do |payment|
        #   save_pending_file(payment['id'], 'payments', payment)
        # end

      elsif payload_key.pluralize == 'invoices'

        if !use_customer_email_param
          if use_customer_object?
            customer = object['customer']
          else
            customer = QBWC::Request::Orders.build_customer_from_order(object)
          end
          
          save_pending_file(customer['name'], 'customers', customer)
        end

        if auto_create_products
          if use_product_objects?
            products = object['products']
          else
            products = QBWC::Request::Orders.build_products_from_order(objects)
          end

          products.flatten.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

        if auto_create_payments
          payments = QBWC::Request::Orders.build_payments_from_order(object)
          payments.each do |payment|
            next unless (payment[:id] && payment[:customer] && payment[:amount] && payment[:payment_method])
            file = "#{path.base_name}/#{path.two_phase_pending}/payments_#{payment[:id]}_.json"
            amazon_s3.export file_name: file, objects: [payment]
          end
        end

      elsif payload_key.pluralize == 'payments'

        if !use_customer_email_param
          customer = QBWC::Request::Orders.build_customer_from_order(object)
          save_pending_file(customer['name'], 'customers', customer)
        end

      elsif payload_key.pluralize == 'creditmemos'

        if !use_customer_email_param
          if use_customer_object?
            customer = object['customer']
          else
            customer = QBWC::Request::Orders.build_customer_from_order(object)
          end
          save_pending_file(customer['name'], 'customers', customer)
        end

        ## TODO: Look for the invoice?

      elsif payload_key.pluralize == 'purchaseorders'

        if !use_customer_email_param
          if use_vendor_object?
            vendor = object['supplier']
          else
            vendor = QBWC::Request::Purchaseorders.build_vendor_from_purchaseorder(object)
          end

          save_pending_file(vendor['name'], 'vendors', vendor)
        end

        if auto_create_products
          if use_product_objects?
            products = object['products']
          else
            products = QBWC::Request::Orders.build_products_from_order(objects)
          end
          
          products.flatten.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

        # payments = QBWC::Request::Orders.build_payments_from_order(object)
        # payments.flatten.each do |payment|
        #   save_pending_file(payment['id'], 'payments', payment)
        # end

      elsif payload_key.pluralize == 'salesreceipts'

        if !use_customer_email_param
          if use_customer_object?
            customer = object['customer']
          else
            customer = QBWC::Request::Orders.build_customer_from_order(object)
          end
          
          save_pending_file(customer['name'], 'customers', customer)
        end

        if auto_create_products
          if use_product_objects?
            products = object['products']
          else
            products = QBWC::Request::Orders.build_products_from_order(objects)
          end

          products.flatten.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

        # payments = QBWC::Request::Orders.build_payments_from_order(object)
        # payments.flatten.each do |payment|
        #   save_pending_file(payment['id'], 'payments', payment)
        # end

      elsif payload_key.pluralize == 'shipments'

        customer = QBWC::Request::Shipments.build_customer_from_shipments(object)
        save_pending_file(customer['name'], 'customers', customer)

        order    = QBWC::Request::Shipments.build_order_from_shipments(object)
        save_pending_file(order['id'], 'orders', order)

        # payment  = QBWC::Request::Shipments.build_payment_from_shipments(object)
        # save_pending_file(payment['id'], 'payments', order)

        if auto_create_products
          products = QBWC::Request::Shipments.build_products_from_shipments(objects)
          products.each do |product|
            save_pending_file(product['id'], 'products', product)
          end
        end

      end
    end

    def save_pending_file(object_ref, object_type, object)
      amazon_s3.export file_name: "#{path.base_name}/#{path.pending}/#{object_type}_#{object_ref}_.json", objects: [object]
    end

    def use_customer_email_param?
      !@config[:quickbooks_customer_email].nil? && !@config[:quickbooks_customer_email].empty?
    end

    def two_phase?
      %w(orders shipments invoices salesreceipts purchaseorders payments inventories creditmemos).include?(payload_key.pluralize)
    end


    def id_of_object(object)
      id = id_for_object(object, payload_key.pluralize)
      id = id.to_s
      id = id.gsub("/","-")
      id = id.gsub("(","-")
      id = id.gsub(")","-")
      id
    end

    def id_for_object(object, object_type)
      return object['id'] if object_type.nil?
      return object['list_id'] if object['list_id']

      key = object_type.pluralize
      if key == 'customers'
        raise "#{object_type.singularize} object is missing name field. Object ID: #{object['id']}" unless object['name']
        sanitize_filename object['name']
      elsif key == 'payments'
        sanitize_filename object['id']
      elsif key == 'shipments'
        raise "#{object_type.singularize} object is missing name field. Object ID: #{object['id']}" unless object['name']
        sanitize_filename object['name']
      elsif key == 'vendors'
        sanitize_filename (object['name'] || object['id'])
      elsif PLURAL_PRODUCT_OBJECT_TYPES.include?(key)
        raise "#{object_type.singularize} object is missing product_id field. Object ID: #{object['id']}" unless object['product_id']
        sanitize_filename object['product_id']
      else
        sanitize_filename object['id']
      end
    end

    def sanitize_filename(id)
      return id unless id.is_a?(String)
      id.gsub('/', '-backslash-')
    end

    def type_and_identifier_filename(object, identifier)
      type = object.is_a?(Hash) ? object[:object_type] : object
      "#{type.pluralize}_#{sanitize_filename(identifier)}_"
    end

    def list_id_and_edit_sequence(object)
      "#{object[:list_id]}_#{object[:edit_sequence]}"
    end

    def should_log_s3_obj_movement?(id)
      IDS_TO_LOG_S3_OBJ_MOVEMENT.include?(id)
    end

    def should_retry_pending_object?(s3_object_json, last_modified)
      s3_object_json['qbe_integration_retry_counter'].to_i < RETRY_CUTOFF &&
      is_old_enough_to_be_moved?(last_modified)
    end

    def is_old_enough_to_be_moved?(last_modified)
      s3_settings = Persistence::Settings.new(config)
      # If web connector is off/stuck, we shouldn't necesarily retry these?
      return false if s3_settings.healthceck_is_failing?

      now = Time.now.utc
      difference_in_minutes = (now - last_modified) / 60.0
      difference_in_minutes > retry_pending_threshold_min_amount
    end

    def retry_pending_threshold_min_amount
      begin
        # Threshold should be at least 5 minutes to allow for connector to run a couple times
        param_as_int = config[:retry_pending_threshold_min_amount].to_i
        param_as_int < 5 ? DEFAULT_PENDING_THRESHOLD_MINS : param_as_int
      rescue NoMethodError => e
        raise e, "The param retry_pending_threshold_min_amount may be incorrect. It should be an integer value or removed so the default value (30) is used. Error Message: #{e.message}"
      end
    end
  end
end
