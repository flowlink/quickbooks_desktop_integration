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

  context '#add_xml_to_send' do
    it 'outputs the right data' do
      vendor = QBWC::Request::Vendors.add_xml_to_send(flowlink_vendor, 12345, config)
      expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_add.gsub(/\s+/, ""))
    end

    describe 'test blank values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_vendor
        object['firstname'] = ''

        vendor = QBWC::Request::Vendors.add_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<FirstName></FirstName>")
      end

      it 'outputs ref field blank correctly when using string field' do
        object = flowlink_vendor
        object['class_name'] = ''

        vendor = QBWC::Request::Vendors.add_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ClassRef><FullName></FullName></ClassRef>")
      end

      it 'outputs ref field blank correctly when using an object' do
        object = flowlink_vendor
        object['class_name'] = {'list_id' => ''}

        vendor = QBWC::Request::Vendors.add_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ClassRef><ListID></ListID></ClassRef>")
      end

      it 'outputs aggregate field blank correctly' do
        object = flowlink_vendor
        object['ship_from_address'] = {}

        vendor = QBWC::Request::Vendors.add_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ShipAddress/>")
      end
    end

    describe 'test nil values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_vendor
        object['firstname'] = nil
        object['contacts'] = nil

        vendor = QBWC::Request::Vendors.add_xml_to_send(object, 12345, config)
      end
    end
  end

  context '#update_xml_to_send' do
    it 'outputs the right data' do
      vendor = QBWC::Request::Vendors.update_xml_to_send(flowlink_vendor, 12345, config)
      expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_update.gsub(/\s+/, ""))
    end

    it "has external_guid field and outputs data without the external_guid field" do
      vendor = QBWC::Request::Vendors.update_xml_to_send(flowlink_vendor, 12345, config)
      expect(vendor.gsub(/\s+/, "")).not_to include("{71562455-3E41-42CA-9377-9A26597C1BD0}")
      expect(vendor.gsub(/\s+/, "")).not_to include("<ExternalGUID>")
    end

    describe 'test blank values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_vendor
        object['firstname'] = ''

        vendor = QBWC::Request::Vendors.update_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<FirstName></FirstName>")
      end

      it 'outputs ref field blank correctly when using string field' do
        object = flowlink_vendor
        object['class_name'] = ''

        vendor = QBWC::Request::Vendors.update_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ClassRef><FullName></FullName></ClassRef>")
      end

      it 'outputs ref field blank correctly when using an object' do
        object = flowlink_vendor
        object['class_name'] = {'list_id' => ''}

        vendor = QBWC::Request::Vendors.update_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ClassRef><ListID></ListID></ClassRef>")
      end

      it 'outputs aggregate field blank correctly' do
        object = flowlink_vendor
        object['ship_from_address'] = {}

        vendor = QBWC::Request::Vendors.update_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).to include("<ShipAddress/>")
      end
    end

    describe 'test nil values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_vendor
        object['firstname'] = nil
        object['contacts'] = nil

        vendor = QBWC::Request::Vendors.update_xml_to_send(object, 12345, config)
        expect(vendor.gsub(/\s+/, "")).not_to include("<FirstName>")
      end
    end
  end

  describe "search xml" do
    it "has list_id and calls search_xml_by_id" do
      # Call search_xml method with flowlink_vendor
      pending("expect the search_xml_by_id method to have been called")
      pending("expect the search_xml_by_name method to NOT have been called")
      this_should_not_get_executed
    end

    it "does not have list_id and calls search_xml_by_name" do
      flowlink_vendor.delete(:list_id)
      # Call search_xml method with flowlink_vendor
      pending("expect the search_xml_by_name method to have been called")
      pending("expect the search_xml_by_id method to NOT have been called")
      this_should_not_get_executed
    end

    it "calls search_xml_by_id and outputs the right data" do
      vendor = QBWC::Request::Vendors.search_xml_by_id("qbe-vendor-listid", 12345)
      expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_search_id.gsub(/\s+/, ""))
    end
  
    it "calls search_xml_by_name and outputs the right data" do
      vendor = QBWC::Request::Vendors.search_xml_by_name("My ID", 12345)
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
