require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/credit_memo_query_rs'

RSpec.describe QBWC::Response::CreditMemoQueryRs do
  describe "calls inventories_to_flowlink" do
    let(:credit_memo) { JSON.parse(File.read('spec/qbwc/response/credit_memo_fixtures/credit_memo.json')) }
    let(:expected_memo) {
      {
        "key"=>["qbe_id", "external_guid"],
        "created_at"=>"2015-02-04T17:22:56-05:00",
        "modified_at"=>"2015-02-04T17:22:56-05:00",
        "total" => "0",
        "billing_address"=>{},
        "shipping_address"=>{},
        "line_items" => [
          {
            "product_id"=>"test-sku", "name"=>"test-sku", "sku"=>"test-sku",
            "quantity"=>"12", "line_item_quantity"=>"12", "warehouse"=>"DFW",
            "service_date"=>""
          }
        ],
        "po_number" => "test",
        "invoice" => {"po_number"=> "test"},
        "order" => {"po_number"=> "test"},
        "relationships" => [{"key"=>"po_number", "object"=>"invoice"}, {"key"=>"po_number", "object"=>"order"}],
        "ship_date"=>""
      }
    }

    describe "calls inventories_to_flowlink with one inventory returned" do
      it "returns fields specific to inventory items" do
        service_rs = QBWC::Response::CreditMemoQueryRs.new([credit_memo])
        output = service_rs.send(:to_flowlink).first.with_indifferent_access
        expect(output).to eq(expected_memo.with_indifferent_access)
      end
    end

  end
end
