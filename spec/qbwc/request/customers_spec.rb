require 'rspec'
require 'json'
require 'qbwc/request/customers'

RSpec.describe QBWC::Request::Customers do
  let(:flowlink_customer) { JSON.parse(File.read('spec/fixtures/customer_from_flowlink.json')) }

  it "calls add_xml_to_send and outputs the right data" do
    customer = described_class.add_xml_to_send(flowlink_customer, 12345)
    puts customer.gsub(/\s+/, "")
    puts "****************"
    puts qbe_customer_add.gsub(/\s+/, "")
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_add.gsub(/\s+/, ""))
  end

  it "calls update_xml_to_send and outputs the right data" do
    customer = described_class.update_xml_to_send(flowlink_customer, 12345)
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_update.gsub(/\s+/, ""))
  end

  def qbe_customer_add
    <<~XML
      <CustomerAddRq requestID="12345">
        <CustomerAdd>
        #{qbe_customer_innards}
        </CustomerAdd>
      </CustomerAddRq>
    XML
  end

  def qbe_customer_update
    <<~XML
      <CustomerModRq requestID="12345">
        <CustomerMod>
          <ListID>12345</ListID>
          <EditSequence>1010101</EditSequence>
          #{qbe_customer_innards}
        </CustomerMod>
      </CustomerModRq>
    XML
  end

  def qbe_customer_innards
    <<~XML
      <Name>First Last</Name>
      <FirstName>First</FirstName>
      <LastName>Last</LastName>
      <Phone>+1 2345678999</Phone>
      <AltPhone>1234567890</AltPhone>
      <Email>test@aol.com</Email>
      <IsActive>true</IsActive>
      <CompanyName>some company</CompanyName>
      <Salutation>Mr</Salutation>
      <MiddleName>middlename</MiddleName>
      <JobTitle>Developer</JobTitle>
      <Fax>1234</Fax>
      <Cc>some_email@test.com</Cc>
      <Contact>My Contact friend</Contact>
      <AltContact>My Other Contact friend</AltContact>
      <ResaleNumber>300</ResaleNumber>
      <CreditLimit>10000</CreditLimit>
      <JobStartDate>2019-11-01T13:22:02.718+00:00</JobStartDate>
      <JobProjectedEndDate>2019-11-01T13:22:02.718+00:00</JobProjectedEndDate>
      <JobEndDate>2019-11-01T13:22:02.718+00:00</JobEndDate>
      <JobDesc>Desc</JobDesc>
      <Notes>A note here</Notes>
      <ExternalGUID>1234</ExternalGUID>
      <TaxRegistrationNumber>0099</TaxRegistrationNumber>
      <OpenBalance>2500</OpenBalance>
      <OpenBalanceDate>2019-11-01T13:22:02.718+00:00</OpenBalanceDate>
      <ClassRef><FullName>class_reference</FullName></ClassRef>
      <ParentRef><FullName>parent_reference</FullName></ParentRef>
      <CustomerTypeRef><FullName>customer_type_reference</FullName></CustomerTypeRef>
      <TermsRef><FullName>terms_reference</FullName></TermsRef>
      <SalesRepRef><FullName>sales_rep_reference</FullName></SalesRepRef>
      <SalesTaxCodeRef><FullName>sales_tax_code_reference</FullName></SalesTaxCodeRef>
      <ItemSalesTaxRef><FullName>item_sales_tax_reference</FullName></ItemSalesTaxRef>
      <PreferredPaymentMethodRef><FullName>preferred_payment_method_reference</FullName></PreferredPaymentMethodRef>
      <JobTypeRef><FullName>job_type_reference</FullName></JobTypeRef>
      <PriceLevelRef><FullName>price_level_reference</FullName></PriceLevelRef>
      <CurrencyRef><FullName>currency_reference</FullName></CurrencyRef>
      <SalesTaxCountry>US</SalesTaxCountry>
      <JobStatus>Awarded</JobStatus>
      <PreferredDeliveryMethod>Email</PreferredDeliveryMethod>
      <BillAddress>
      <Addr1>75 example dr</Addr1>
      <Addr2>addr line 2</Addr2>
      <Addr3>addr line 3</Addr3>
      <Addr4>addr line 4</Addr4>
      <Addr5>addr line 5</Addr5>
      <City>Some City</City>
      <State>California</State>
      <PostalCode>78456</PostalCode>
      <Country>United States</Country>
      <Note>vendor address note</Note>
      </BillAddress>
      <ShipAddress>
      <Addr1>75 example dr</Addr1>
      <Addr2>addr line 2</Addr2>
      <Addr3>addr line 3</Addr3>
      <Addr4>addr line 4</Addr4>
      <Addr5>addr line 5</Addr5>
      <City>Some City</City>
      <State>California</State>
      <PostalCode>78456</PostalCode>
      <Country>United States</Country>
      <Note>ship address note</Note>
      </ShipAddress>
      <ShipToAddress>
      <Name>Ship To Name</Name>
      <DefaultShipTo>false</DefaultShipTo>
      <Addr1>75 example dr</Addr1>
      <Addr2>addr line 2</Addr2>
      <Addr3>addr line 3</Addr3>
      <Addr4>addr line 4</Addr4>
      <Addr5>addr line 5</Addr5>
      <City>Some City</City>
      <State>California</State>
      <PostalCode>78456</PostalCode>
      <Country>United States</Country>
      <Note>ship address note</Note>
      </ShipToAddress>
      <ShipToAddress>
      <Name>Ship To Name</Name>
      <DefaultShipTo>true</DefaultShipTo>
      <Addr1>75 example dr</Addr1>
      <Addr2>addr line 2</Addr2>
      <Addr3>addr line 3</Addr3>
      <Addr4>addr line 4</Addr4>
      <Addr5>addr line 5</Addr5>
      <City>Some City</City>
      <State>California</State>
      <PostalCode>78456</PostalCode>
      <Country>United States</Country>
      <Note>ship address note</Note>
      </ShipToAddress>
      <AdditionalContactRef>
      <ContactName>initial contact</ContactName>
      <ContactValue>initial value</ContactValue>
      </AdditionalContactRef>
      <AdditionalContactRef>
      <ContactName>secondary contact</ContactName>
      <ContactValue>secondary value</ContactValue>
      </AdditionalContactRef>
      <AdditionalNotes><Note>note #1</Note></AdditionalNotes>
      <Contacts>
      <Salutation>Miss</Salutation>
      <FirstName>Lady</FirstName>
      <MiddleName>middle</MiddleName>
      <LastName>Surname</LastName>
      <JobTitle>Thinker</JobTitle>
      <AdditionalContactRef>
      <ContactName>initial contact 1</ContactName>
      <ContactValue>initial value 1</ContactValue>
      </AdditionalContactRef>
      <AdditionalContactRef>
      <ContactName>secondary contact 1</ContactName>
      <ContactValue>secondary value 1</ContactValue>
      </AdditionalContactRef>
      </Contacts>
      <Contacts>
      <Salutation>Dr</Salutation>
      <FirstName>John</FirstName>
      <MiddleName>F</MiddleName>
      <LastName>Doe</LastName>
      <JobTitle>Doctor</JobTitle>
      </Contacts>
    XML
  end
end