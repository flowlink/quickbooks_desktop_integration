require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/customer_query_rs'

RSpec.describe QBWC::Response::CustomerQueryRs do
  let(:qbe_customer) { JSON.parse(File.read('spec/qbwc/response/customer_fixtures/customer_from_qbe.json')) }
  let(:base_flowlink_customer) { JSON.parse(File.read('spec/qbwc/response/customer_fixtures/customer_output.json')) }

  describe "calls to_flowlink" do
    it "with a payload of one customer and outputs the right data" do
      expected_customer = base_flowlink_customer.with_indifferent_access
      
      customer_rs_class = QBWC::Response::CustomerQueryRs.new([qbe_customer])
      output = customer_rs_class.send(:to_flowlink).first.with_indifferent_access

      expect(output).to eq(expected_customer)
    end
  end
end