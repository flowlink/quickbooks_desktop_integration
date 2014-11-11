require 'spec_helper'

describe QBWC::Response::ItemInventoryQueryRs do
  subject { described_class.new Factory.item_inventory_query_rs_hash }

  describe '#to_wombat' do
    it 'converts to wombat format' do
      expect(subject.send(:to_wombat).size).to eq 1
    end
  end

  it "sets records as an array" do
    records = Factory.item_inventory_query_rs_hash
    subject = described_class.new records
    expect(subject.send(:to_wombat)).to be_a Array

    records = Factory.item_inventory_query_rs_multiple_hash
    subject = described_class.new records
    expect(subject.send(:to_wombat)).to be_a Array
  end

  it "parse empty response" do
    records = Factory.item_inventory_query_rs_empty_hash
    subject = described_class.new records
    expect(subject.send(:to_wombat)).to be_empty
  end

  it "persists objects in s3" do
    config = {
      connection_id: "54591b3a5869632afc090000",
      receive: [{'inventory' => [] }]
    }

    VCR.use_cassette "response/543543254325342" do
      subject.process config
    end
  end
end
