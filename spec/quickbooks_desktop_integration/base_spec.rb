require 'spec_helper'

module QuickbooksDesktopIntegration
  describe Base do
    it "defaults to wombat on config origin" do
      subject = described_class.new
      expect(subject.config[:origin]).to eq 'wombat'

      subject = described_class.new {}
      expect(subject.config[:origin]).to eq 'wombat'

      subject = described_class.new origin: 'quickbooks'
      expect(subject.config[:origin]).to eq 'quickbooks'
    end

    it "persists s3 file" do
      xml = Factory.item_inventory_query_rs_multiple_qbxml
      inventory = Inventory.new xml

      payload = { inventories: inventory.mapped_records }
      config = { origin: 'quickbooks', account_id: 'x123' }

      VCR.use_cassette "base/3455243523535" do
        subject = described_class.new config, payload
        subject.save_to_s3
      end
    end

    it "reads all data in s3 from particular account" do
      config = { origin: 'quickbooks', account_id: 'x123' }

      VCR.use_cassette "base/2342343214124" do
        subject = described_class.new config
        records = subject.start_processing "integrated"
      end
    end

    it "reads from s3 and returns records collection" do
      payload = { inventories: {} }
      config = { origin: 'quickbooks', account_id: 'x123' }

      VCR.use_cassette "base/45344235454" do
        subject = described_class.new config, payload
        inventories = subject.start_processing "integrated"
      end
    end
  end
end
