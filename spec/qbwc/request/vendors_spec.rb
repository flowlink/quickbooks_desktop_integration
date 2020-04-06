require 'rspec'
require 'json'
require 'qbwc/request/vendors'
require 'qbwc/request/vendor_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Vendors do
  let(:flowlink_vendor) { JSON.parse(File.read('spec/fixtures/vendor_from_flowlink.json')) }
  let(:config) {
    {
      job_type_name: "job_type_reference",
      price_level_name: "price_level_reference",
      quickbooks_currency_name: "currency_reference"
    }
  }

  it "calls add_xml_to_send and outputs the right data" do
    vendor = described_class.add_xml_to_send(flowlink_vendor, 12345, config)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_add.gsub(/\s+/, ""))
  end

  it "calls update_xml_to_send and outputs the right data" do
    vendor = described_class.update_xml_to_send(flowlink_vendor, 12345, config)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_update.gsub(/\s+/, ""))
  end

  it "calls search_xml_by_id and outputs the right data" do
    vendor = described_class.search_xml_by_id("My ID", 12345)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_search_id.gsub(/\s+/, ""))
  end

  it "calls search_xml_by_name and outputs the right data" do
    vendor = described_class.search_xml_by_name("My ID", 12345)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_search_name.gsub(/\s+/, ""))
  end
end
