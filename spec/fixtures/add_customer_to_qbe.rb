<<~XML
  <CustomerAddRq requestID="12345">
    <CustomerAdd>
      <Name>FirstLast</Name>
      <IsActive>true</IsActive>
      <ClassRef>
        <FullName>class_reference</FullName>
      </ClassRef>
      <ParentRef>
        <FullName>parent_reference</FullName>
      </ParentRef>
      <CompanyName>somecompany</CompanyName>
      <Salutation>Mr</Salutation>
      <FirstName>First</FirstName>
      <MiddleName>middlename</MiddleName>
      <LastName>Last</LastName>
      <JobTitle>Developer</JobTitle>
      <BillAddress>
        <Addr1>75exampledr</Addr1>
        <Addr2>addrline2</Addr2>
        <Addr3>addrline3</Addr3>
        <Addr4>addrline4</Addr4>
        <Addr5>addrline5</Addr5>
        <City>SomeCity</City>
        <State>California</State>
        <PostalCode>78456</PostalCode>
        <Country>UnitedStates</Country>
        <Note>vendoraddressnote</Note>
      </BillAddress>
      <ShipAddress>
        <Addr1>75exampledr</Addr1>
        <Addr2>addrline2</Addr2>
        <Addr3>addrline3</Addr3>
        <Addr4>addrline4</Addr4>
        <Addr5>addrline5</Addr5>
        <City>SomeCity</City>
        <State>California</State>
        <PostalCode>78456</PostalCode>
        <Country>UnitedStates</Country>
        <Note>shipaddressnote</Note>
      </ShipAddress>
      <ShipToAddress>
        <Name>ShipToName</Name>
        <Addr1>75exampledr</Addr1>
        <Addr2>addrline2</Addr2>
        <Addr3>addrline3</Addr3>
        <Addr4>addrline4</Addr4>
        <Addr5>addrline5</Addr5>
        <City>SomeCity</City>
        <State>California</State>
        <PostalCode>78456</PostalCode>
        <Country>UnitedStates</Country>
        <Note>shipaddressnote</Note>
        <DefaultShipTo>false</DefaultShipTo>
      </ShipToAddress>
      <ShipToAddress>
        <Name>ShipToName</Name>
        <Addr1>75exampledr</Addr1>
        <Addr2>addrline2</Addr2>
        <Addr3>addrline3</Addr3>
        <Addr4>addrline4</Addr4>
        <Addr5>addrline5</Addr5>
        <City>SomeCity</City>
        <State>California</State>
        <PostalCode>78456</PostalCode>
        <Country>UnitedStates</Country>
        <Note>shipaddressnote</Note>
        <DefaultShipTo>true</DefaultShipTo>
      </ShipToAddress>
      <Phone>+12345678999</Phone>
      <AltPhone>1234567890</AltPhone>
      <Fax>1234</Fax>
      <Email>test@aol.com</Email>
      <Cc>some_email@test.com</Cc>
      <Contact>MyContactfriend</Contact>
      <AltContact>MyOtherContactfriend</AltContact>
      <AdditionalContactRef>
        <ContactName>initialcontact</ContactName>
        <ContactValue>initialvalue</ContactValue>
      </AdditionalContactRef>
      <AdditionalContactRef>
        <ContactName>secondarycontact</ContactName>
        <ContactValue>secondaryvalue</ContactValue>
      </AdditionalContactRef>
      <Contacts>
        <Salutation>Miss</Salutation>
        <FirstName>Lady</FirstName>
        <MiddleName>middle</MiddleName>
        <LastName>Surname</LastName>
        <JobTitle>Thinker</JobTitle>
        <AdditionalContactRef>
          <ContactName>initialcontact1</ContactName>
          <ContactValue>initialvalue1</ContactValue>
        </AdditionalContactRef>
        <AdditionalContactRef>
          <ContactName>secondarycontact1</ContactName>
          <ContactValue>secondaryvalue1</ContactValue>
        </AdditionalContactRef>
      </Contacts>
      <Contacts>
        <Salutation>Dr</Salutation>
        <FirstName>John</FirstName>
        <MiddleName>F</MiddleName>
        <LastName>Doe</LastName>
        <JobTitle>Doctor</JobTitle>
      </Contacts>
      <CustomerTypeRef>
        <FullName>customer_type_reference</FullName>
      </CustomerTypeRef>
      <TermsRef>
        <FullName>terms_reference</FullName>
      </TermsRef>
      <SalesRepRef>
        <FullName>sales_rep_reference</FullName>
      </SalesRepRef>
      <OpenBalance>2500</OpenBalance>
      <OpenBalanceDate>2019-11-01T13:22:02.718+00:00</OpenBalanceDate>
      <SalesTaxCodeRef>
        <FullName>sales_tax_code_reference</FullName>
      </SalesTaxCodeRef>
      <ItemSalesTaxRef>
        <FullName>item_sales_tax_reference</FullName>
      </ItemSalesTaxRef>
      <SalesTaxCountry>US</SalesTaxCountry>
      <ResaleNumber>300</ResaleNumber>
      <AccountNumber>123</AccountNumber>
      <CreditLimit>10000</CreditLimit>
      <PreferredPaymentMethodRef>
        <FullName>preferred_payment_method_reference</FullName>
      </PreferredPaymentMethodRef>
      <JobStatus>Awarded</JobStatus>
      <JobStartDate>2019-11-01T13:22:02.718+00:00</JobStartDate>
      <JobProjectedEndDate>2019-11-01T13:22:02.718+00:00</JobProjectedEndDate>
      <JobEndDate>2019-11-01T13:22:02.718+00:00</JobEndDate>
      <JobDesc>Desc</JobDesc>
      <JobTypeRef>
        <FullName>job_type_reference</FullName>
      </JobTypeRef>
      <Notes>Anotehere</Notes>
      <AdditionalNotes>
        <Note>note#1</Note>
      </AdditionalNotes>
      <PreferredDeliveryMethod>Email</PreferredDeliveryMethod>
      <PriceLevelRef>
        <FullName>price_level_reference</FullName>
      </PriceLevelRef>
      <ExternalGUID>1234</ExternalGUID>
      <TaxRegistrationNumber>0099</TaxRegistrationNumber>
      <CurrencyRef>
        <FullName>currency_reference</FullName>
      </CurrencyRef>
    </CustomerAdd>
  </CustomerAddRq>
XML