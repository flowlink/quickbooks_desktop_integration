require 'spec_helper'

module Persistence
  describe Object do
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
        expect(objects.first).to have_key('products')
      end
    end
  end
end
