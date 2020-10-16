require 'rspec'
require 'time'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'qbwc/request/salesreceipts'
require 'qbwc/request/adjustments'
require 'qbwc/request/salesreceipt_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Salesreceipts do
  describe "add_xml_to_send" do
    let(:session_id) { "123aksjdfklajsdfkl" }
    let(:sales_receipt) {
      {
        "id": "#21487",
        "pos": false,
        "name": "#21487",
        "note": "",
        "tags": "Printed",
        "email": "test@test.com",
        "notes": [],
        "source": "test.myshopify.com",
        "status": "completed",
        "totals": {
          "tax": 4.87,
          "item": 64.99,
          "order": 69.86,
          "refund": 0,
          "payment": 69.86,
          "discount": 0,
          "shipping": 0
        },
        "channel": "web",
        "refunds": [],
        "currency": "USD",
        "placed_on": "2020-03-01T10:56:03-08:00",
        "line_items": [
          {
            "name": "test item",
            "grams": 0,
            "price": 64.99,
            "taxable": true,
            "quantity": 1,
            "gift_card": false,
            "product_id": "test",
            "product_exists": true,
            "requires_shipping": true,
            "fulfillment_service": "manual",
            "fulfillable_quantity": 0,
          }
        ],
        "pos_string": "false",
        "tags_array": [
          {
            "tag": "Printed"
          }
        ],
        "updated_at": "2020-03-04T14:52:42-08:00",
        "adjustments": [
          {
            "name": "Tax",
            "value": 4.87
          },
          {
            "name": "Shipping",
            "value": 0
          },
          {
            "name": "Discounts",
            "value": 0
          }
        ],
        "order_number": "21487",
        "shopify_name": "#21487",
        "tax_line_items": [
          {
            "tax_item": "CA State Tax",
            "amount": 4.87
          }
        ],
        "billing_address": {
          "city": "Pittsburgh",
          "state": "Pennsylvania",
          "company": nil,
          "country": "US",
          "zipcode": "99999",
          "address1": "250 Main St",
          "address2": "",
          "lastname": "Last",
          "firstname": "First"
        },
        "shipping_method": "Free Domestic US Shipping (5-7 Business Days)",
        "signifyd_status": "Pending",
        "financial_status": "paid",
        "shipping_address": {
          "city": "Pittsburgh",
          "state": "Pennsylvania",
          "company": nil,
          "country": "US",
          "zipcode": "99999",
          "address1": "250 Main St",
          "address2": "",
          "lastname": "Last",
          "firstname": "First"
        },
        "fulfillment_status": "fulfilled",
        "shopify_location_id": "",
        "customer": {
          "name": "Test customer"
        },
        "request_id": "kajshdfhsldjf-as-4443-af62-10bc840a74a6"
      }
    }
    let(:configs) {
      {
        "origin": "flowlink",
        "payload_type": "sales_receipt",
        "connection_id": "nurelmremote",
        "quickbooks_tax_item": "Sales Tax",
        "quickbooks_cogs_account": "Cost of Goods Sold",
        "quickbooks_discount_item": "Discount",
        "quickbooks_shipping_item": "Shipping",
        "quickbooks_income_account": "Merchandized Sales",
        "quickbooks_use_tax_line_items": "1"
      }
    }

    it "use_tax_line_items dont use rate if not given" do
      request_xml = QBWC::Request::Salesreceipts.add_xml_to_send(sales_receipt.with_indifferent_access, configs.with_indifferent_access, session_id)
      expect(request_xml).to include("<FullName>CA State Tax</FullName>\n</ItemRef>\n<Desc></Desc>\n\n\n\n\n<Amount>4.87</Amount>")
    end

    it 'sets the tax_list_id if its given' do
      edited_receipt = sales_receipt
      edited_receipt[:line_items][0][:tax_code_id] = 'Tax'
      request_xml = QBWC::Request::Salesreceipts.add_xml_to_send(edited_receipt.with_indifferent_access, configs.with_indifferent_access, session_id)
      expect(request_xml).to include("<SalesTaxCodeRef>")
      expect(request_xml).not_to include("<ListID>")
    end

    it 'sets the tax_list_id if its given' do
      edited_receipt = sales_receipt
      list_id = "80000053-1550177824"
      edited_receipt[:line_items][0][:tax_code_id] = 'Tax'
      edited_receipt[:line_items][0][:tax_list_id] = list_id
      request_xml = QBWC::Request::Salesreceipts.add_xml_to_send(edited_receipt.with_indifferent_access, configs.with_indifferent_access, session_id)
      expect(request_xml).to include("<ListID>#{list_id}</ListID>")
    end
  end

  describe "add update and search xml" do
    let(:flowlink_salesreceipt) { JSON.parse(File.read('spec/qbwc/request/salesreceipt_fixtures/salesreceipt_from_flowlink.json')).with_indifferent_access }
    config = {
      class_name: "class name here"
    }

    it "matches expected xml when calling add_xml_to_send" do
      request_xml = QBWC::Request::Salesreceipts.add_xml_to_send(flowlink_salesreceipt, config, 12345)
      expect(request_xml.gsub(/\s+/, "")).to eq(qbe_salesreceipt_add.gsub(/\s+/, ""))
    end

    it "uses object value over config value to set certain fields" do
      flowlink_salesreceipt[:class_name] = "a different class name"
      expected_string = "<ClassRef><FullName>adifferentclassname</FullName></ClassRef>"

      request_xml = QBWC::Request::Salesreceipts.add_xml_to_send(flowlink_salesreceipt, config, 12345)
      expect(request_xml.gsub(/\s+/, "")).to include(expected_string)
    end

    it "matches expected xml when calling update_xml_to_send" do
      flowlink_salesreceipt[:list_id] = "qbe-salesreceipt-listid-for-update"
      flowlink_salesreceipt[:edit_sequence] = "1010101"
      
      request_xml = QBWC::Request::Salesreceipts.update_xml_to_send(flowlink_salesreceipt, config, 12345)
      expect(request_xml.gsub(/\s+/, "")).to eq(qbe_salesreceipt_update.gsub(/\s+/, ""))
    end

    it 'calls search_xml_by_id and outputs the right data' do
      search_xml = QBWC::Request::Salesreceipts.search_xml('qbe-salesreceipt-listid', 12345)
      expect(search_xml.gsub(/\s+/, "")).to eq(qbe_salesreceipt_search_id.gsub(/\s+/, ""))
    end
  end
end
