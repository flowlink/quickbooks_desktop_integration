require 'spec_helper'

module Persistence
  describe Object do
    let(:error) {
                 {
                  code: '3200',
                  message: 'The provided edit sequence "1416315972" is out-of-date. ',
                  request_id: 'f9a42f99-03fc-4847-b71e-0091baa4e3ef'
                  }
                }

    it "defaults to wombat on config origin" do
      subject = described_class.new
      expect(subject.config[:origin]).to eq 'wombat'

      subject = described_class.new {}
      expect(subject.config[:origin]).to eq 'wombat'

      subject = described_class.new origin: 'quickbooks'
      expect(subject.config[:origin]).to eq 'quickbooks'
    end

    it "persists s3 file" do
      payload = Factory.products
      config = { origin: 'wombat', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette "persistence/save_products" do
        subject = described_class.new config, payload
        subject.save
      end
    end

    it "#process_pending_objects" do
      payload = Factory.products
      config = { origin: 'wombat', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette "persistence/process_pending_objects" do
        subject = described_class.new config, payload
        subject.process_pending_objects
      end
    end

    it "#get_ready_objects_to_send" do
      payload = Factory.products
      config = { origin: 'wombat', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette "persistence/get_ready_objects" do
        subject = described_class.new config, payload
        objects = subject.get_ready_objects_to_send

        expect(objects.first).to have_key('inventories')
      end
    end

    it "#update_objects_with_query_results" do
      objects_to_be_renamed = [Factory.query_results_to_update_objects]
      config = { origin: 'wombat', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette "persistence/update_objects_with_query_results" do
        subject = described_class.new config, {}
        subject.update_objects_with_query_results(objects_to_be_renamed)
      end
    end

    it "#update_objects_files" do
      payload = Factory.products
      statuses_objects = Factory.objects_results_status
      config = { origin: 'wombat', connection_id: '54372cb069702d1f59000000' }

      VCR.use_cassette "persistence/update_objects_files" do
        subject = described_class.new config, payload
        subject.update_objects_files(statuses_objects)
      end
    end

    it "#get_notifications" do
      payload = Factory.products
      config = { origin: 'wombat', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette "persistence/get_notifications" do
        subject = described_class.new config, payload
        notifications = subject.get_notifications
        expect(notifications).to have_key('processed')
        expect(notifications['processed'].size).to eq(0)
      end
    end

    it "#create_error_notifications" do
      payload = Factory.products
      config = { origin: 'wombat', connection_id: '53ab0943436f6e9a6f080000' }

      VCR.use_cassette "persistence/create_error_notifications" do
        subject = described_class.new config, payload
        subject.create_error_notifications( error.merge({context: 'Modifying products'}),
                                            "products",
                                            error[:request_id])
      end
    end
  end
end
