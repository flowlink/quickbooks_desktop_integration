require 'spec_helper'

module Persistence
  describe Object do
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

    it 'persists s3 file' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/save_products' do
        subject = described_class.new config, payload
        subject.save
      end
    end

    it '#process_pending_objects' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/process_pending_objects' do
        subject = described_class.new config, payload
        subject.process_pending_objects
      end
    end

    it '#get_ready_objects_to_send' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/get_ready_objects' do
        subject = described_class.new config, payload
        objects = subject.get_ready_objects_to_send

        expect(objects.first).to have_key('products')
      end
    end

    it '#update_objects_with_query_results' do
      objects_to_be_renamed = [Factory.query_results_to_update_objects]
      config = { origin: 'flowlink', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette 'persistence/update_objects_with_query_results' do
        subject = described_class.new config, {}
        subject.update_objects_with_query_results(objects_to_be_renamed)
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

    it '#get_notifications' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette 'persistence/get_notifications' do
        subject = described_class.new config, payload
        notifications = subject.get_notifications
        expect(notifications).to have_key('processed')
        expect(notifications['processed'].size).to eq(0)
      end
    end

    it '#create_error_notifications' do
      payload = Factory.products
      config = { origin: 'flowlink', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette 'persistence/create_error_notifications' do
        subject = described_class.new config, payload
        subject.create_error_notifications(error.merge(context: 'Modifying products'),
                                           'products',
                                           error[:request_id])
      end
    end

    it '#generate_inserts_for_two_phase' do
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
  end
end
