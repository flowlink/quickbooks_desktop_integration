def qbe_salesreceipt_search_id
  <<~XML
    <SalesReceiptQueryRq requestID="12345">
      <RefNumberCaseSensitive>qbe-salesreceipt-listid</RefNumberCaseSensitive>
      <IncludeLineItems>true</IncludeLineItems>
    </SalesReceiptQueryRq>
  XML
end

def qbe_salesreceipt_add
  <<~XML
    <SalesReceiptAddRq requestID="12345">
      <SalesReceiptAdd>
      #{qbe_salesreceipt_innards(false)}
      </SalesReceiptAdd>
    </SalesReceiptAddRq>
  XML
end

def qbe_salesreceipt_update
  <<~XML
    <SalesReceiptModRq requestID="12345">
      <SalesReceiptMod>
        <TxnID>qbe-salesreceipt-listid-for-update</TxnID>
        <EditSequence>1010101</EditSequence>
        #{qbe_salesreceipt_innards(true)}
      </SalesReceiptMod>
    </SalesReceiptModRq>
  XML
end

def qbe_salesreceipt_innards(is_mod)
  external_guid = is_mod ? "" : "<ExternalGUID>35cb4e30-54e1-49f9-b5ce-4134799eb2c0</ExternalGUID>"
  
  line_begin_name = is_mod ? "<SalesReceiptLineMod>" : "<SalesReceiptLineAdd>"
  line_end_name = is_mod ? "</SalesReceiptLineMod>" : "</SalesReceiptLineAdd>"
  txn_line_id = is_mod ? "<TxnLineID>-1</TxnLineID>" : ""

  <<~XML
    <CustomerRef>
      <FullName>Mr Rich Guy</FullName>
    </CustomerRef>
    <ClassRef>
      <FullName>class name here</FullName>
    </ClassRef>
    <TemplateRef>
      <FullName>my template 1</FullName>
    </TemplateRef>
    <TxnDate>12/26/2019</TxnDate>
    <RefNumber>1999</RefNumber>
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
    <IsPending>false</IsPending>
    <CheckNumber>90</CheckNumber>
    <PaymentMethodRef>
      <FullName>CASH</FullName>
    </PaymentMethodRef>
    <DueDate>12/31/2019</DueDate>
    <SalesRepRef>
      <FullName>FlowLink Admin</FullName>
    </SalesRepRef>
    <ShipDate>01/20/2020</ShipDate>
    <ShipMethodRef>
      <FullName>Fedex</FullName>
    </ShipMethodRef>
    <FOB>what</FOB>
    <ItemSalesTaxRef>
      <FullName>sales tax 10</FullName>
    </ItemSalesTaxRef>
    <Memo>Hi</Memo>
    <CustomerMsgRef>
      <FullName>Thanks</FullName>
    </CustomerMsgRef>
    <IsToBePrinted>true</IsToBePrinted>
    <IsToBeEmailed>true</IsToBeEmailed>
    <IsTaxIncluded>false</IsTaxIncluded>
    <CustomerSalesTaxCodeRef>
      <FullName>555</FullName>
    </CustomerSalesTaxCodeRef>
    <DepositToAccountRef>
      <FullName>Undeposited Funds</FullName>
    </DepositToAccountRef>
    <Other>some value</Other>
    <ExchangeRate>0.1</ExchangeRate>
    #{external_guid}
    #{line_begin_name}
      #{txn_line_id}
      <ItemRef>
        <FullName>ABC Product</FullName>
      </ItemRef>
      <Desc>description for ABC</Desc>
      <Quantity>10</Quantity>
      <Rate>110.00</Rate>
      <InventorySiteRef>
        <FullName>Site number one</FullName>
      </InventorySiteRef>
    #{line_end_name}
    #{line_begin_name}
      #{txn_line_id}
      <ItemRef>
        <FullName>XYZ Product</FullName>
      </ItemRef>
      <Desc>description for XYZ</Desc>
      <Quantity>1</Quantity>
      <Rate>49.00</Rate>
      <InventorySiteRef>
        <FullName>Site number two</FullName>
      </InventorySiteRef>
    #{line_end_name}
  XML
end