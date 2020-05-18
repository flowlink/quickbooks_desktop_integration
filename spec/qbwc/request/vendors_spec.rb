require 'rspec'
require 'json'
require 'qbwc/request/vendors'
require 'qbwc/request/vendor_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Vendors do
  let(:flowlink_vendor) { JSON.parse(File.read('spec/qbwc/request/vendor_fixtures/vendor_from_flowlink.json')) }
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

  it "calls update_xml_to_send with an external_guid and outputs data without the external_guid field" do
    vendor = described_class.update_xml_to_send(flowlink_vendor, 12345, config)
    expect(vendor.gsub(/\s+/, "")).not_to include("{71562455-3E41-42CA-9377-9A26597C1BD0}")
    expect(vendor.gsub(/\s+/, "")).not_to include("<ExternalGUID>")
  end

  describe "search xml" do
    it "has list_id and calls search_xml_by_id" do
      # Call search_xml method with flowlink_customer
      pending("expect the search_xml_by_id method to have been called")
      pending("expect the search_xml_by_name method to NOT have been called")
      this_should_not_get_executed
    end

    it "does not have list_id and calls search_xml_by_name" do
      flowlink_vendor.delete(:list_id)
      # Call search_xml method with flowlink_customer
      pending("expect the search_xml_by_name method to have been called")
      pending("expect the search_xml_by_id method to NOT have been called")
      this_should_not_get_executed
    end

    it "calls search_xml_by_id and outputs the right data" do
      vendor = described_class.search_xml_by_id("qbe-vendor-listid", 12345)
      expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_search_id.gsub(/\s+/, ""))
    end
  
    it "calls search_xml_by_name and outputs the right data" do
      vendor = described_class.search_xml_by_name("My ID", 12345)
      expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_search_name.gsub(/\s+/, ""))
    end
  end

  describe 'calls pre_mapping_logic' do
    describe 'checks is_active field' do
      it 'starts as nil and returns true' do
        flowlink_vendor['is_active'] = nil
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['is_active']).to be true
      end
      it 'starts as true and returns true' do
        flowlink_vendor['is_active'] = true
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['is_active']).to be true
      end
      it 'starts as false and returns false' do
        flowlink_vendor['is_active'] = false
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['is_active']).to be false
      end
      it 'starts as a random string and returns true' do
        flowlink_vendor['is_active'] = 'some other value'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['is_active']).to be true
      end
    end
    describe 'checks first and last name fields' do
      it 'given nil for first and last name field, it returns correct parts of name field' do
        flowlink_vendor['firstname'] = nil
        flowlink_vendor['lastname'] = nil
        flowlink_vendor['name'] = 'Test Customer Name'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['firstname']).to eq('Test')
        expect(vendor['lastname']).to eq('Name')
      end

      it 'given valid values for first and last name field, it returns those values' do
        flowlink_vendor['firstname'] = 'NuRelm'
        flowlink_vendor['lastname'] = 'Dev'
        flowlink_vendor['name'] = 'Test Customer Name'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['firstname']).to eq('NuRelm')
        expect(vendor['lastname']).to eq('Dev')
      end

      it 'given nil for first and last name field and non-splittable string, it returns that string for both first and last name' do
        flowlink_vendor['firstname'] = nil
        flowlink_vendor['lastname'] = nil
        flowlink_vendor['name'] = 'Test'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['firstname']).to eq('Test')
        expect(vendor['lastname']).to eq('Test')
      end

      it 'given nil for first and last name and name fields, it returns nil for both first and last name' do
        flowlink_vendor['firstname'] = nil
        flowlink_vendor['lastname'] = nil
        flowlink_vendor['name'] = nil
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['firstname']).to be_nil
        expect(vendor['lastname']).to be_nil
      end
    end
    describe 'checks phone and mobile fields' do
      it 'has valid phone and mobile values and returns those values' do
        flowlink_vendor['vendor_address']['phone'] = '123-456-7890'
        flowlink_vendor['ship_from_address']['phone'] = '111-555-9999'
        flowlink_vendor['phone'] = '1'
        flowlink_vendor['mobile'] = '2'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['phone']).to eq('1')
        expect(vendor['mobile']).to eq('2')
      end

      it 'has nil for phone and mobile and returns nil' do
        flowlink_vendor['vendor_address']['phone'] = '123-456-7890'
        flowlink_vendor['ship_from_address']['phone'] = '111-555-9999'
        flowlink_vendor['phone'] = nil
        flowlink_vendor['mobile'] = nil
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['phone']).to be_nil
        expect(vendor['mobile']).to be_nil
      end

      it 'has nil for phone, mobile, and address fields and returns nil' do
        flowlink_vendor['vendor_address'] = nil
        flowlink_vendor['ship_from_address'] = nil
        flowlink_vendor['phone'] = nil
        flowlink_vendor['mobile'] = nil
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['phone']).to be_nil
        expect(vendor['mobile']).to be_nil
      end
    end
    describe 'checks reporting period and sales tax country fields' do
      it 'given valid values and returns an object with correct fields' do
        flowlink_vendor['reporting_period'] = 'Monthly'
        flowlink_vendor['sales_tax_country'] = 'Australia'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['reporting_period']).to eq('Monthly')
        expect(vendor['sales_tax_country']).to eq('Australia')
      end

      it 'given nil values and returns an object with nil for those fields' do
        flowlink_vendor['reporting_period'] = nil
        flowlink_vendor['sales_tax_country'] = nil
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['reporting_period']).to be_nil
        expect(vendor['sales_tax_country']).to be_nil
      end
      
      it 'given invalid non-nil values and returns an object with nil for those fields' do
        flowlink_vendor['reporting_period'] = 'Yearly'
        flowlink_vendor['sales_tax_country'] = 'India'
        vendor = QBWC::Request::Vendors.send(:pre_mapping_logic, flowlink_vendor)
        expect(vendor['reporting_period']).to be_nil
        expect(vendor['sales_tax_country']).to be_nil
      end
    end
  end
end
