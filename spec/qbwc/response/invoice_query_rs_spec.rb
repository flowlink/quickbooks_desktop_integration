require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/invoice_query_rs'

RSpec.describe QBWC::Response::InvoiceQueryRs do
  describe "calls inventories_to_flowlink" do
    let(:invoice_object) { JSON.parse(File.read('spec/qbwc/response/invoice_fixtures/invoice.json')) }
    let(:expected_invoice) {
      {
        "key"=>["qbe_transaction_id", "qbe_id", "external_guid"],
        "created_at"=>"2015-02-04T17:22:56-05:00",
        "modified_at"=>"2015-02-04T17:22:56-05:00",
        "customer"=>{
          "name"=>nil,
          "external_id"=>nil,
          "qbe_id"=>nil
        },
        "billing_address"=>{},
        "shipping_address"=>{},
        "po_number"=>"1ABC",
        "due_date"=>"",
        "sales_rep"=>{"name"=>nil},
        "shipping_date"=>"",
        "suggested_discount_date"=>"",
        "sales_order"=>{"purchase_order_number"=>"1ABC"},
        "relationships"=>[
          {"object"=>"customer", "key"=>"qbe_id"},
          {"object"=>"product", "key"=>"qbe_id", "location"=>"line_items"},
          {"object"=>"order", "key"=>"purchase_order_number", "location"=>"sales_order"}
        ]
      }
    }

    describe "calls invoices_to_flowlink with one invoice returned" do
      it "returns expected fields" do
        invoice_rs = QBWC::Response::InvoiceQueryRs.new([invoice_object])
        output = invoice_rs.send(:invoices_to_flowlink).first.with_indifferent_access
        expect(output).to eq(expected_invoice.with_indifferent_access)
      end

    end

  end
end
