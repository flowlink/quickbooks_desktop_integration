def qbe_vendor_search_name
  <<~XML
    <VendorQueryRq requestID="12345">
      <MaxReturned>50</MaxReturned>
      <NameRangeFilter>
        <FromName>My ID</FromName>
        <ToName>My ID</ToName>
      </NameRangeFilter>
    </VendorQueryRq>
  XML
end

def qbe_vendor_search_id
  <<~XML
    <VendorQueryRq requestID="12345">
      <ListID>My ID</ListID>
    </VendorQueryRq>
  XML
end

def qbe_vendor_add
  <<~XML
    <VendorAddRq requestID="12345">
      <VendorAdd>
      #{qbe_vendor_innards(false)}
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
        #{qbe_vendor_innards(true)}
      </VendorMod>
    </VendorModRq>
  XML
end

def qbe_vendor_innards(is_mod)
  contact_open = is_mod ? "<ContactsMod>" : "<Contacts>"
  contact_closed = is_mod ? "</ContactsMod>" : "</Contacts>"
  add_notes_open = is_mod ? "<AdditionalNotesMod><NoteID>1</NoteID>" : "<AdditionalNotes>"
  add_notes_closed = is_mod ? "</AdditionalNotesMod>" : "</AdditionalNotes>"
  <<~XML
    <Name>First Last</Name>
    <IsActive>true</IsActive>
    <ClassRef><FullName>class_reference</FullName></ClassRef>
    <CompanyName>some company</CompanyName>
    <Salutation>Mr</Salutation>
    <FirstName>First</FirstName>
    <MiddleName>middlename</MiddleName>
    <LastName>Last</LastName>
    <JobTitle>Developer</JobTitle>
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
    <NameOnCheck>First M Last</NameOnCheck>
    <AccountNumber>11111</AccountNumber>
    <Notes>A note here</Notes>
    #{add_notes_open}<Note>note #1</Note>#{add_notes_closed}
    <VendorTypeRef><FullName>vendor_type_reference</FullName></VendorTypeRef>
    <TermsRef><FullName>terms_reference</FullName></TermsRef>
    <CreditLimit>10000</CreditLimit>
    <VendorTaxIdent>1</VendorTaxIdent>
    <IsVendorEligibleFor1099>false</IsVendorEligibleFor1099>
    <OpenBalance>2500</OpenBalance>
    <OpenBalanceDate>2019-11-01T13:22:02.718+00:00</OpenBalanceDate>
    <BillingRateRef><FullName>billing_rate_reference</FullName></BillingRateRef>
    <ExternalGUID>1234</ExternalGUID>
    <SalesTaxCodeRef><FullName>sales_tax_code_reference</FullName></SalesTaxCodeRef>
    <SalesTaxCountry>US</SalesTaxCountry>
    <IsSalesTaxAgency>false</IsSalesTaxAgency>
    <SalesTaxReturnRef><FullName>sales_tax_return_reference</FullName></SalesTaxReturnRef>
    <TaxRegistrationNumber>0099</TaxRegistrationNumber>
    <ReportingPeriod>Quarterly</ReportingPeriod>
    <IsTaxTrackedOnPurchases>false</IsTaxTrackedOnPurchases>
    <TaxOnPurchasesAccountRef><FullName>tax_on_purchases_account_reference</FullName></TaxOnPurchasesAccountRef>
    <IsTaxTrackedOnSales>false</IsTaxTrackedOnSales>
    <TaxOnSalesAccountRef><FullName>tax_on_sales_account_reference</FullName></TaxOnSalesAccountRef>
    <IsTaxOnTax>false</IsTaxOnTax>
    <CurrencyRef><FullName>currency_reference</FullName></CurrencyRef>
  XML
end
