require 'rspec'
require 'json'
require 'qbwc/request/vendors'

RSpec.describe QBWC::Request::Vendors do
  let(:flowlink_vendor) { JSON.parse(File.read('spec/fixtures/vendor_from_flowlink.json')) }

  it "calls add_xml_to_send and outputs the right data" do
    vendor = described_class.add_xml_to_send(flowlink_vendor, 12345)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_add.gsub(/\s+/, ""))
  end

  it "calls update_xml_to_send and outputs the right data" do
    vendor = described_class.update_xml_to_send(flowlink_vendor, 12345)
    expect(vendor.gsub(/\s+/, "")).to eq(qbe_vendor_update.gsub(/\s+/, ""))
  end

  def qbe_vendor_add
    <<~XML
      <VendorAddRq requestID="12345">
        <VendorAdd>
        #{qbe_vendor_innards}
        </VendorAdd>
      </VendorAddRq>
    XML
  end

  def qbe_vendor_update
    <<~XML
      <VendorModRq requestID="12345">
        <VendorMod>
          <ListID>12345</ListID>
          <EditSequence>1010101</EditSequence>
          #{qbe_vendor_innards}
        </VendorMod>
      </VendorModRq>
    XML
  end

  def qbe_vendor_innards
    <<~XML
      <Name>First Last</Name>
      <FirstName>First</FirstName>
      <LastName>Last</LastName>
      <Phone>+1 2345678999</Phone>
      <AltPhone>1234567890</AltPhone>
      <Email>test@aol.com</Email>
      <IsActive>true</IsActive>
      <Salutation>Mr</Salutation>
      <MiddleName>middlename</MiddleName>
      <JobTitle>Developer</JobTitle>
      <Fax>1234</Fax>
      <Cc>some_email@test.com</Cc>
      <Contact>My Contact friend</Contact>
      <AltContact>My Other Contact friend</AltContact>
      <CreditLimit>10000</CreditLimit>
      <VendorTaxIdent>1</VendorTaxIdent>
      <IsVendorEligibleFor1099>false</IsVendorEligibleFor1099>
      <OpenBalance>2500</OpenBalance>
      <OpenBalanceDate>2019-11-01T13:22:02.718+00:00</OpenBalanceDate>
      <ExternalGUID>1234</ExternalGUID>
      <NameOnCheck>First M Last</NameOnCheck>
      <AccountNumber>11111</AccountNumber>
      <Notes>A note here</Notes>
      <IsSalesTaxAgency>false</IsSalesTaxAgency>
      <TaxRegistrationNumber>0099</TaxRegistrationNumber>
      <IsTaxTrackedOnPurchases>false</IsTaxTrackedOnPurchases>
      <IsTaxTrackedOnSales>false</IsTaxTrackedOnSales>
      <IsTaxOnTax>false</IsTaxOnTax>
      <CompanyName>some company</CompanyName>
      <SalesTaxCountry>US</SalesTaxCountry>
      <ReportingPeriod>Quarterly</ReportingPeriod>
      <ClassRef><FullName>class_reference</FullName></ClassRef>
      <BillingRateRef><FullName>billing_rate_reference</FullName></BillingRateRef>
      <VendorTypeRef><FullName>vendor_type_reference</FullName></VendorTypeRef>
      <TermsRef><FullName>terms_reference</FullName></TermsRef>
      <SalesTaxCodeRef><FullName>sales_tax_code_reference</FullName></SalesTaxCodeRef>
      <SalesTaxReturnRef><FullName>sales_tax_return_reference</FullName></SalesTaxReturnRef>
      <TaxOnPurchasesAccountRef><FullName>tax_on_purchases_account_reference</FullName></TaxOnPurchasesAccountRef>
      <TaxOnSalesAccountRef><FullName>tax_on_sales_account_reference</FullName></TaxOnSalesAccountRef>
      <CurrencyRef><FullName>currency_reference</FullName></CurrencyRef>
      <VendorAddress>
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
      </VendorAddress>
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
    XML
  end
end
