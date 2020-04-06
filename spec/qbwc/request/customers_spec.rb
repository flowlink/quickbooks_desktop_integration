require 'rspec'
require 'json'
require 'qbwc/request/customers'
require 'qbwc/request/customer_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Customers do
  let(:flowlink_customer) { JSON.parse(File.read('spec/fixtures/customer_from_flowlink.json')) }
  let(:config) {
    {
      job_type_name: "job_type_reference",
      price_level_name: "price_level_reference",
      quickbooks_currency_name: "currency_reference"
    }
  }

  it "calls add_xml_to_send and outputs the right data" do
    customer = described_class.add_xml_to_send(flowlink_customer, 12345, config)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_add.gsub(/\s+/, ""))
  end

  it "calls update_xml_to_send and outputs the right data" do
    customer = described_class.update_xml_to_send(flowlink_customer, 12345, config)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_update.gsub(/\s+/, ""))
  end

  it "calls search_xml_by_id and outputs the right data" do
    customer = described_class.search_xml_by_id("My ID", 12345)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_search_id.gsub(/\s+/, ""))
  end

  it "calls search_xml_by_name and outputs the right data" do
    customer = described_class.search_xml_by_name("My ID", 12345)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_search_name.gsub(/\s+/, ""))
  end
end