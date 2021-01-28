require 'rspec'
require 'json'
require 'qbwc/request/customers'
require 'qbwc/request/customer_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Customers do
  let(:flowlink_customer) { JSON.parse(File.read('spec/qbwc/request/customer_fixtures/customer_from_flowlink.json')) }
  let(:config) {
    {
      job_type_name: 'job_type_reference',
      price_level_name: 'price_level_reference',
      quickbooks_currency_name: 'currency_reference'
    }
  }

  context '#add_xml_to_send' do
    it 'outputs the right data' do
      customer = QBWC::Request::Customers.add_xml_to_send(flowlink_customer, 12345, config)
      expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_add.gsub(/\s+/, ""))
    end

    describe 'test blank values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_customer
        object['firstname'] = ''

        customer = QBWC::Request::Customers.add_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<FirstName></FirstName>")
      end

      it 'outputs ref field blank correctly when using string field' do
        object = flowlink_customer
        object['class_name'] = ''

        customer = QBWC::Request::Customers.add_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ClassRef><FullName></FullName></ClassRef>")
      end

      it 'outputs ref field blank correctly when using an object' do
        object = flowlink_customer
        object['class_name'] = {'list_id' => ''}

        customer = QBWC::Request::Customers.add_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ClassRef><ListID></ListID></ClassRef>")
      end

      it 'outputs aggregate field blank correctly' do
        object = flowlink_customer
        object['shipping_address'] = {}

        customer = QBWC::Request::Customers.add_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ShipAddress/>")
      end
    end

    describe 'test nil values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_customer
        object['firstname'] = nil
        object['contacts'] = nil

        customer = QBWC::Request::Customers.add_xml_to_send(object, 12345, config)
      end
    end
  end

  context '#update_xml_to_send' do
    it 'outputs the right data' do
      customer = QBWC::Request::Customers.update_xml_to_send(flowlink_customer, 12345, config)
      expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_update.gsub(/\s+/, ""))
    end

    describe 'test blank values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_customer
        object['firstname'] = ''

        customer = QBWC::Request::Customers.update_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<FirstName></FirstName>")
      end

      it 'outputs ref field blank correctly when using string field' do
        object = flowlink_customer
        object['class_name'] = ''

        customer = QBWC::Request::Customers.update_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ClassRef><FullName></FullName></ClassRef>")
      end

      it 'outputs ref field blank correctly when using an object' do
        object = flowlink_customer
        object['class_name'] = {'list_id' => ''}

        customer = QBWC::Request::Customers.update_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ClassRef><ListID></ListID></ClassRef>")
      end

      it 'outputs aggregate field blank correctly' do
        object = flowlink_customer
        object['shipping_address'] = {}

        customer = QBWC::Request::Customers.update_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).to include("<ShipAddress/>")
      end
    end

    describe 'test nil values' do
      it 'outputs basic field blank correctly' do
        object = flowlink_customer
        object['firstname'] = nil
        object['contacts'] = nil

        customer = QBWC::Request::Customers.update_xml_to_send(object, 12345, config)
        expect(customer.gsub(/\s+/, "")).not_to include("<FirstName>")
      end
    end
  end

  describe "search xml" do
    it "has list_id and calls search_xml_by_id" do
      # Call search_xml method with flowlink_customer
      pending("expect the search_xml_by_id method to have been called")
      pending("expect the search_xml_by_name method to NOT have been called")
      this_should_not_get_executed
    end

    it "does not have list_id and calls search_xml_by_name" do
      flowlink_customer.delete(:list_id)
      # Call search_xml method with flowlink_customer
      pending("expect the search_xml_by_name method to have been called")
      pending("expect the search_xml_by_id method to NOT have been called")
      this_should_not_get_executed
    end

    it 'calls search_xml_by_id and outputs the right data' do
      customer = QBWC::Request::Customers.search_xml_by_id('qbe-customer-listid', 12345)
      expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_search_id.gsub(/\s+/, ""))
    end
  
    it 'calls search_xml_by_name and outputs the right data' do
      customer = QBWC::Request::Customers.search_xml_by_name('Bruce Wayne', 12345)
      expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_search_name.gsub(/\s+/, ""))
    end
  end

  describe 'calls pre_mapping_logic' do
    describe 'checks is_active field' do
      it 'starts as nil and returns true' do
        flowlink_customer['is_active'] = nil
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['is_active']).to be true
      end

      it 'starts as true and returns true' do
        flowlink_customer['is_active'] = true
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['is_active']).to be true
      end

      it 'starts as false and returns false' do
        flowlink_customer['is_active'] = false
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['is_active']).to be false
      end

      it 'starts as a random string and returns true' do
        flowlink_customer['is_active'] = 'some other value'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['is_active']).to be true
      end
    end

    describe 'checks job status, preferred delivery method and sales tax country fields' do
      it 'given valid values and returns an object with correct fields' do
        flowlink_customer['sales_tax_country'] = 'Australia'
        flowlink_customer['job_status'] = 'Awarded'
        flowlink_customer['preferred_delivery_method'] = 'Email'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['sales_tax_country']).to eq('Australia')
        expect(customer['job_status']).to eq('Awarded')
        expect(customer['preferred_delivery_method']).to eq('Email')
      end

      it 'given nil values and returns an object with nil for those fields' do
        flowlink_customer['sales_tax_country'] = nil
        flowlink_customer['job_status'] = nil
        flowlink_customer['preferred_delivery_method'] = nil
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['sales_tax_country']).to be_nil
        expect(customer['job_status']).to be_nil
        expect(customer['preferred_delivery_method']).to be_nil
      end

      it 'given invalid non-nil values and returns an object with nil for those fields' do
        flowlink_customer['sales_tax_country'] = 'Custom Delivery Method'
        flowlink_customer['job_status'] = 'Fiired'
        flowlink_customer['preferred_delivery_method'] = 'Phone'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['sales_tax_country']).to be_nil
        expect(customer['job_status']).to be_nil
        expect(customer['preferred_delivery_method']).to be_nil
      end
    end
  end
end