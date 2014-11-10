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

    # it "reads all data in s3 from particular account" do
    #   config = { origin: 'quickbooks', account_id: 'x123' }

    #   VCR.use_cassette "base/2342343214124" do
    #     subject = described_class.new config
    #     records = subject.start_processing "integrated"
    #   end
    # end

    # it "reads from s3 and returns records collection" do
    #   payload = { inventories: {} }
    #   config = { origin: 'quickbooks', account_id: 'x123' }

    #   VCR.use_cassette "base/452353452342" do
    #     subject = described_class.new config, payload
    #     inventories = subject.start_processing "integrated"
    #   end
    # end
  end
end
