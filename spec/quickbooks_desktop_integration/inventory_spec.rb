require 'spec_helper'

module QuickbooksDesktopIntegration
  describe Inventory do
    it "sets records as an array" do
      body = Factory.item_inventory_query_rs_qbxml
      subject = described_class.new body
      expect(subject.records).to be_a Array

      body = Factory.item_inventory_query_rs_multiple_qbxml
      subject = described_class.new body
      expect(subject.records).to be_a Array
    end

    it "parse empty response" do
      body = Factory.item_inventory_query_rs_empty_qbxml
      subject = described_class.new body
      expect(subject.records).to be_empty
    end

    it "maps records" do
      body = Factory.item_inventory_query_rs_multiple_qbxml
      subject = described_class.new body
      expect(subject.mapped_records).to be_a Array
    end
  end
end
