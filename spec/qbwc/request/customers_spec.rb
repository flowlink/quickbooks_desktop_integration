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

  it 'calls add_xml_to_send and outputs the right data' do
    customer = QBWC::Request::Customers.add_xml_to_send(flowlink_customer, 12345, config)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_add.gsub(/\s+/, ""))
  end

  it 'calls update_xml_to_send and outputs the right data' do
    customer = QBWC::Request::Customers.update_xml_to_send(flowlink_customer, 12345, config)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_update.gsub(/\s+/, ""))
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

    describe 'checks first and last name fields' do
      it 'given nil for first and last name field, it returns correct parts of name field' do
        flowlink_customer['firstname'] = nil
        flowlink_customer['lastname'] = nil
        flowlink_customer['name'] = 'Test Customer Name'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['firstname']).to eq('Test')
        expect(customer['lastname']).to eq('Name')
      end

      it 'given valid values for first and last name field, it returns those values' do
        flowlink_customer['firstname'] = 'NuRelm'
        flowlink_customer['lastname'] = 'Dev'
        flowlink_customer['name'] = 'Test Customer Name'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['firstname']).to eq('NuRelm')
        expect(customer['lastname']).to eq('Dev')
      end

      it 'given nil for first and last name field and non-splittable string, it returns that string for both first and last name' do
        flowlink_customer['firstname'] = nil
        flowlink_customer['lastname'] = nil
        flowlink_customer['name'] = 'Test'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['firstname']).to eq('Test')
        expect(customer['lastname']).to eq('Test')
      end

      it 'given nil for first and last name and name fields, it returns nil for both first and last name' do
        flowlink_customer['firstname'] = nil
        flowlink_customer['lastname'] = nil
        flowlink_customer['name'] = nil
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['firstname']).to be_nil
        expect(customer['lastname']).to be_nil
      end
    end

    describe 'checks phone and mobile fields' do
      it 'has valid phone and mobile values and returns those values' do
        flowlink_customer['billing_address']['phone'] = '123-456-7890'
        flowlink_customer['shipping_address']['phone'] = '111-555-9999'
        flowlink_customer['phone'] = '1'
        flowlink_customer['mobile'] = '2'
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['phone']).to eq('1')
        expect(customer['mobile']).to eq('2')
      end

      it 'has nil for phone and mobile and returns valid address phone fields' do
        flowlink_customer['billing_address']['phone'] = '123-456-7890'
        flowlink_customer['shipping_address']['phone'] = '111-555-9999'
        flowlink_customer['phone'] = nil
        flowlink_customer['mobile'] = nil
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['phone']).to eq('123-456-7890')
        expect(customer['mobile']).to eq('111-555-9999')
      end

      it 'has nil for phone, mobile, and address fields and returns nil' do
        flowlink_customer['billing_address'] = nil
        flowlink_customer['shipping_address'] = nil
        flowlink_customer['phone'] = nil
        flowlink_customer['mobile'] = nil
        customer = QBWC::Request::Customers.send(:pre_mapping_logic, flowlink_customer)
        expect(customer['phone']).to be_nil
        expect(customer['mobile']).to be_nil
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