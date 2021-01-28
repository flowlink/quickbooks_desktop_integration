require 'spec_helper'

module Persistence
  describe Object do
    before(:each) do
      Aws.config[:stub_responses] = false
    end
    let(:error) do
      {
        code: '3200',
        message: 'The provided edit sequence "1416315972" is out-of-date. ',
        request_id: 'f9a42f99-03fc-4847-b71e-0091baa4e3ef'
      }
    end

    it 'defaults to flowlink on config origin' do
      subject = described_class.new
      expect(subject.config[:origin]).to eq 'flowlink'

      subject = described_class.new {}
      expect(subject.config[:origin]).to eq 'flowlink'

      subject = described_class.new origin: 'quickbooks'
      expect(subject.config[:origin]).to eq 'quickbooks'
    end

    xit 'persists s3 file' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/save_products' do
        subject = described_class.new config, payload
        subject.save
      end
    end

    xit '#process_pending_objects' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/process_pending_objects' do
        subject = described_class.new config, payload
        subject.process_pending_objects
      end
    end

    xit '#get_ready_objects_to_send' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/get_ready_objects' do
        subject = described_class.new config, payload
        objects = subject.get_ready_objects_to_send

        expect(objects.first).to have_key('products')
      end
    end

    describe '#update_objects_with_query_results' do
      objects_to_be_renamed = [Factory.query_results_to_update_objects]
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }
      xit 'vcr spec' do
        VCR.use_cassette 'persistence/update_objects_with_query_results' do
          subject = described_class.new config, {}
          subject.update_objects_with_query_results(objects_to_be_renamed)
        end
      end

      xit 'finds filename using list_id correctly' do
        # Mock S3 to have 1 file in the specific folder with the filename "products_800000-88888_.json"
        # Call update_objects_with_query_results
        # Expect NO errors to be raise/rescued since we should find the file using the list_id first of all
        # Expect that the new content has the new edit_sequence field equal to '12312312321'
        existing_file_name = "products_800000-88888_.json"
        subject = described_class.new(config, {})
        subject.update_objects_with_query_results(objects_to_be_renamed)
        pending("expect this to not raise any errors")
        pending("Expect that the new content has the new edit_sequence field equal to '12312312321'")
        this_should_not_get_executed
      end

      xit 'finds filename using product_id correctly' do
        # Mock S3 to have 1 file in the specific folder with the filename "products_SPREE-T-SHIRT293178_.json"
        # Call update_objects_with_query_results
        # Expect an error to be raised because we SHOULD look for "products_800000-88888_.json" as the filename first
        # Rescue error and expect that the correct file is found
        # Expect that the new content has the new edit_sequence field equal to '12312312321'
        existing_file_name = "products_SPREE-T-SHIRT293178_.json"
        subject = described_class.new(config, {})
        subject.update_objects_with_query_results(objects_to_be_renamed)
        pending("expect this to raise 1 error because it cannot find the file using list_id as our identifier")
        pending("Expect that the new content has the new edit_sequence field equal to '12312312321'")
        this_should_not_get_executed
      end
    end

    it '#update_objects_files' do
      payload = Factory.products
      statuses_objects = Factory.objects_results_status
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/update_objects_files' do
        subject = described_class.new config, payload
        subject.update_objects_files(statuses_objects)
      end
    end

    xit '#get_notifications' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette 'persistence/get_notifications' do
        subject = described_class.new config, payload
        notifications = subject.get_notifications
        expect(notifications).to have_key('processed')
        expect(notifications['processed'].size).to eq(0)
      end
    end

    xit '#create_error_notifications' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette 'persistence/create_error_notifications' do
        subject = described_class.new config, payload
        subject.create_error_notifications(error.merge(context: 'Modifying products'),
                                           'products',
                                           error[:request_id])
      end
    end

    xit '#generate_inserts_for_two_phase' do
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/generate_inserts_for_two_phase' do
        payload = Factory.orders
        object = payload['orders'].first

        subject = described_class.new config, payload
        subject.save

        payload = Factory.shipments
        object = payload['shipments'].first

        subject = described_class.new config, payload
        subject.save
      end
    end

    describe "#id_for_object" do
      let(:config) { { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' } }

      it 'orders use the id field' do
        payload = Factory.orders
        object_type = 'orders'
        object = payload[object_type].first

        subject = described_class.new config, payload

        expect(subject.send(:id_for_object, object, object_type)).to eq object['id']
      end

      it 'products use the product_id field' do
        payload = Factory.products
        object_type = 'products'
        object = payload[object_type].first

        subject = described_class.new config, payload

        expect(subject.send(:id_for_object, object, object_type)).to eq object['product_id']
      end

      it 'returns use the id field' do
        payload = Factory.returns
        object_type = 'returns'
        object = payload[object_type].first

        subject = described_class.new config, payload

        expect(subject.send(:id_for_object, object, object_type)).to eq object['id']
      end

      it 'customers use the name field' do
        payload = Factory.customers
        object_type = 'customers'
        object = payload[object_type].first

        subject = described_class.new config, payload

        expect(subject.send(:id_for_object, object, object_type)).to eq object['name']
      end

      it 'backslashes are filtered but kept in name' do
        payload = Factory.customers_with_backslashes
        object_type = 'customers'
        object = payload[object_type].first
        original_name = object['name'].dup

        subject = described_class.new config, payload

        expect(subject.send(:id_for_object, object, object_type)).not_to include("/")
        expect(object['name']).to eq original_name
      end

      it 'failed notifications for customers use the name field' do
        payload = Factory.customers
        object_type = 'customers'
        object = payload[object_type].first
        notification = {
          "code"=>"3190",
          "message"=>"Cannot clear the element in the IncomeAccountRef field. ",
          "request_id"=>"157366a9-7f1e-49ca-aff8-270bd2dc728b",
          "context"=>"Updating customers",
          "object"=> object
        }
        subject = described_class.new(config, {})

        expect(subject.send(:id_for_object, notification["object"], object_type)).to eq object['name']
      end

      it 'failed notifications for products use the product_id field' do
        payload = Factory.products
        object_type = 'products'
        object = payload[object_type].first
        notification = {
          "code"=>"3190",
          "message"=>"Cannot clear the element in the IncomeAccountRef field. ",
          "request_id"=>"157366a9-7f1e-49ca-aff8-270bd2dc728b",
          "context"=>"Updating products",
          "object"=> object
        }
        subject = described_class.new(config, {})

        expect(subject.send(:id_for_object, notification["object"], object_type)).to eq object['product_id']
      end
      
      describe 'error catching' do
        it 'has valid value for the objects type and does not raise an error' do
          payload = Factory.customers
          object_type = 'customers'
          object = payload[object_type].first
          object['name'] = "my name"

          subject = described_class.new config, payload

          expect { subject.send(:id_for_object, object, object_type) }.to_not raise_error
        end

        it 'customer type is missing name and raises an error' do
          payload = Factory.customers
          object_type = 'customers'
          object = payload[object_type].first
          object.delete(:name)

          subject = described_class.new config, payload

          expect { subject.send(:id_for_object, object, object_type) }.to raise_error("customer object is missing name field. Object ID: #{object['id']}")
        end

        it 'product type is missing product_id and raises an error' do
          payload = Factory.products
          object_type = 'products'
          object = payload[object_type].first
          object.delete(:product_id)

          subject = described_class.new config, payload

          expect { subject.send(:id_for_object, object, object_type) }.to raise_error("product object is missing product_id field. Object ID: #{object['id']}")
        end
      end
    end

    describe "#sanitize_filename" do
      let(:config) { { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' } }

      it 'removes backslashes on a string' do
        id = "My ID / identifier"
        subject = described_class.new config, {}
        expect(subject.send(:sanitize_filename, id)).to eq("My ID -backslash- identifier")
      end

      it 'returns an integer without raising an error' do
        id = 123456
        subject = described_class.new config, {}
        expect(subject.send(:sanitize_filename, id)).to eq(id)
      end

      it 'returns nil without raising an error' do
        id = nil
        subject = described_class.new config, {}
        expect(subject.send(:sanitize_filename, id)).to be_nil
      end
    end

    describe "#type_and_identifier_filename" do
      let(:config) { { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' } }
      identifier = 29103902

      it 'takes a string and works' do
        object = "customer"
        subject = described_class.new(config, {})
        expect(subject.send(:type_and_identifier_filename, object, identifier)).to eq("customers_29103902_")
      end

      it 'takes a hash and works' do
        object = {object_type: "customer"}
        subject = described_class.new(config, {})
        expect(subject.send(:type_and_identifier_filename, object, identifier)).to eq("customers_29103902_")
      end

      it 'takes a hash without the right key and error is raised' do
        object = {invalid_key: "customer"}
        subject = described_class.new(config, {})
        expect { subject.send(:type_and_identifier_filename, object, identifier) }.to raise_error(NoMethodError)
      end
    end

    describe '#should_retry_in_progress_object?' do
      let(:config) { { origin: 'flowlink', connection_id: 'rspec_testing' } }
      let(:s3_converted_json) { { 'qbe_integration_retry_counter' => retry_number} }
      let(:retry_number) { rand(3) }

      describe 'with an object that has been in in_progress for a while' do
        describe 'given json with no qbe_integration_retry_counter key' do
          let(:s3_converted_json) { { 'some_other_key' => retry_number} }
          it 'returns true' do
            subject = described_class.new(config, {})
            expect(subject.send(:should_retry_in_progress_object?, s3_converted_json)).to be true
          end
        end

        describe 'given json with a qbe_integration_retry_counter key greater than or equal to 3' do
          let(:retry_number) { rand(5) + 3 }
          it 'returns false' do
            subject = described_class.new(config, {})
            expect(subject.send(:should_retry_in_progress_object?, s3_converted_json)).to be false
          end
        end

        describe 'given json with a qbe_integration_retry_counter key less than 3' do
          it 'returns true' do
            subject = described_class.new(config, {})
            allow(subject).to receive(:is_old_enough_to_be_moved?).and_return(true)
            expect(subject.send(:should_retry_in_progress_object?, s3_converted_json)).to be true
          end
        end
      end
    end

    describe '#retry_in_progress_objects_that_are_stuck' do
      let(:config_for_retry) { { origin: 'flowlink', connection_id: 'rspec-and-vcr', request_id: "55f4cdd7-a5f6-4fb6-adf0-751905cfedd6" } }
      let(:config_for_removal) { { origin: 'flowlink', connection_id: 'rspec-and-vcr', request_id: "55f4cdd7-a5f6-4fb6-adf0-751905cfedd5" } }
      let(:object_for_retry) { {
        "id" => '1234-test',
        "product_id" => '1234-test',
        "qbe_integration_retry_counter" => 1
      } }
      let(:object_for_removal) { {
        "id" => '5678-test',
        "product_id" => '5678-test',
        "qbe_integration_retry_counter" => 3
      } }
      let(:file_name_for_retry) { 'rspec-and-vcr/flowlink_in_progress/products_1234-test_.json' }
      let(:file_name_for_removal) { 'rspec-and-vcr/flowlink_in_progress/products_5678-test_.json' }

      it 'Moves files' do
        Aws.config[:stub_responses] = false
        VCR.use_cassette 'persistence/move_in_progress' do
          # If you need to re-run the cassette:
          # 1. Delete the cassette
          # 2. Uncomment the 4 commented lines of code below (that start with id assignment)
          # 3. Ensure that scripts/run_tests.sh has the REAL key/secret
          # 4. Run the spec (It will create the file in S3 in the quickbooks-desktop-integration/rspec-and-vcr/flowlink_in_progress folder)
          # 5. Delete the cassette again (since we're not testing the creation of the file, but the moving of the file)
          # 6. Comment the 2 lines of code below (that start with id assignment)
          
          # id = Persistence::Session.save(config_for_retry, object_for_retry)
          # object_for_retry["request_id"] = id
          # amazon_s3 = S3Util.new
          # amazon_s3.export file_name: file_name_for_retry, objects: [object_for_retry]
          
          subject = described_class.new config_for_retry
          subject.retry_in_progress_objects_that_are_stuck
        end
      end

      it 'Removes retried files and creates notification' do
        Aws.config[:stub_responses] = false
        VCR.use_cassette 'persistence/remove_in_progress_and_generate_notification' do
          # If you need to re-run the cassette:
          # 1. Delete the cassette
          # 2. Uncomment the 4 commented lines of code below (that start with id assignment)
          # 3. Ensure that scripts/run_tests.sh has the REAL key/secret
          # 4. Run the spec (It will create the file in S3 in the quickbooks-desktop-integration/rspec-and-vcr/flowlink_in_progress folder)
          # 5. Delete the cassette again (since we're not testing the creation of the file, but the moving of the file)
          # 6. Comment the 4 lines of code below (that start with id assignment)
          
          # id = Persistence::Session.save(config_for_removal, object_for_removal)
          # object_for_removal["request_id"] = id
          # amazon_s3 = S3Util.new
          # amazon_s3.export file_name: file_name_for_removal, objects: [object_for_removal]

          subject = described_class.new config_for_removal
          subject.retry_in_progress_objects_that_are_stuck
        end
      end
    end

  end
end
