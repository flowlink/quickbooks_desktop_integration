require 'rspec'
require 'json'
require 'qbwc/request/customers'

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
    # TODO: change the `qbe_customer_add.gsub(/\s+/, "")` below to instead reference the spec/fixtures/add_customer_to_qbe.xml file
    expect(customer.gsub(/\s+/, "")).to eq(qbe_customer_add.gsub(/\s+/, ""))
  end

  it "calls update_xml_to_send and outputs the right data" do
    customer = described_class.update_xml_to_send(flowlink_customer, 12345, config)
    # TODO: change the `qbe_customer_add.gsub(/\s+/, "")` below to instead reference the spec/fixtures/mod_customer_to_qbe.xml file
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

  def qbe_customer_search_name
    <<~XML
      <CustomerQueryRq requestID="12345">
        <MaxReturned>50</MaxReturned>
        <NameRangeFilter>
          <FromName>My ID</FromName>
          <ToName>My ID</ToName>
        </NameRangeFilter>
      </CustomerQueryRq>
    XML
  end

  def qbe_customer_search_id
    <<~XML
      <CustomerQueryRq requestID="12345">
        <ListID>My ID</ListID>
      </CustomerQueryRq>
    XML
  end

  def qbe_customer_add
    <<~XML
      <CustomerAddRq requestID="12345">
        <CustomerAdd>
        #{qbe_customer_innards(false)}
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
          #{qbe_customer_innards(true)}
        </CustomerMod>
      </CustomerModRq>
    XML
  end

  def qbe_customer_innards(is_mod)
    contact_open = is_mod ? "<ContactsMod>" : "<Contacts>"
    contact_closed = is_mod ? "</ContactsMod>" : "</Contacts>"
    
    add_notes_open = is_mod ? "<AdditionalNotesMod><NoteID>1</NoteID>" : "<AdditionalNotes>"
    add_notes_closed = is_mod ? "</AdditionalNotesMod>" : "</AdditionalNotes>"

    open_balance_items = is_mod ? "" : "<OpenBalance>2500</OpenBalance><OpenBalanceDate>2019-11-01T13:22:02.718+00:00</OpenBalanceDate>"

    guid = is_mod ? "" : "<ExternalGUID>1234</ExternalGUID>"

    <<~XML
      <Name>First Last</Name>
      <IsActive>true</IsActive>
      <ClassRef><FullName>class_reference</FullName></ClassRef>
      <ParentRef><FullName>parent_reference</FullName></ParentRef>
      <CompanyName>some company</CompanyName>
      <Salutation>Mr</Salutation>
      <FirstName>First</FirstName>
      <MiddleName>middlename</MiddleName>
      <LastName>Last</LastName>
      <JobTitle>Developer</JobTitle>
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
      <DefaultShipTo>false</DefaultShipTo>
      </ShipToAddress>
      <ShipToAddress>
      <Name>Ship To Name</Name>
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
      <DefaultShipTo>true</DefaultShipTo>
      </ShipToAddress>
      <Phone>+1 2345678999</Phone>
      <AltPhone>1234567890</AltPhone>
      <Fax>1234</Fax>
      <Email>test@aol.com</Email>
      <Cc>some_email@test.com</Cc>
      <Contact>My Contact friend</Contact>
      <AltContact>My Other Contact friend</AltContact>
      <AdditionalContactRef>
      <ContactName>initial contact</ContactName>
      <ContactValue>initial value</ContactValue>
      </AdditionalContactRef>
      <AdditionalContactRef>
      <ContactName>secondary contact</ContactName>
      <ContactValue>secondary value</ContactValue>
      </AdditionalContactRef>
      #{contact_open}
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
      #{contact_closed}
      #{contact_open}
      <Salutation>Dr</Salutation>
      <FirstName>John</FirstName>
      <MiddleName>F</MiddleName>
      <LastName>Doe</LastName>
      <JobTitle>Doctor</JobTitle>
      #{contact_closed}
      <CustomerTypeRef><FullName>customer_type_reference</FullName></CustomerTypeRef>
      <TermsRef><FullName>terms_reference</FullName></TermsRef>
      <SalesRepRef><FullName>sales_rep_reference</FullName></SalesRepRef>
      #{open_balance_items}
      <SalesTaxCodeRef><FullName>sales_tax_code_reference</FullName></SalesTaxCodeRef>
      <ItemSalesTaxRef><FullName>item_sales_tax_reference</FullName></ItemSalesTaxRef>
      <SalesTaxCountry>US</SalesTaxCountry>
      <ResaleNumber>300</ResaleNumber>
      <AccountNumber>123</AccountNumber>
      <CreditLimit>10000</CreditLimit>
      <PreferredPaymentMethodRef><FullName>preferred_payment_method_reference</FullName></PreferredPaymentMethodRef>
      <JobStatus>Awarded</JobStatus>
      <JobStartDate>2019-11-01T13:22:02.718+00:00</JobStartDate>
      <JobProjectedEndDate>2019-11-01T13:22:02.718+00:00</JobProjectedEndDate>
      <JobEndDate>2019-11-01T13:22:02.718+00:00</JobEndDate>
      <JobDesc>Desc</JobDesc>
      <JobTypeRef><FullName>job_type_reference</FullName></JobTypeRef>
      <Notes>A note here</Notes>
      #{add_notes_open}<Note>note #1</Note>#{add_notes_closed}
      <PreferredDeliveryMethod>Email</PreferredDeliveryMethod>
      <PriceLevelRef><FullName>price_level_reference</FullName></PriceLevelRef>
      #{guid}
      <TaxRegistrationNumber>0099</TaxRegistrationNumber>
      <CurrencyRef><FullName>currency_reference</FullName></CurrencyRef>
    XML
  end
end