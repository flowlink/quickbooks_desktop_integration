def qbe_salestaxproduct_search_name
  <<~XML
    <ItemSalesTaxQueryRq requestID="12345">
      <MaxReturned>10000</MaxReturned>
      <NameRangeFilter>
        <FromName>My Awesome Product</FromName>
        <ToName>My Awesome Product</ToName>
      </NameRangeFilter>
    </ItemSalesTaxQueryRq>
  XML
end

def add_xml_salestaxproduct
  <<~XML
    <ItemSalesTaxAddRq requestID="12345">
      <ItemSalesTaxAdd>
        <Name>test salestax product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef> 
        <ItemDesc>This product is salestax</ItemDesc>
        <TaxRate>0.07</TaxRate>
        <TaxVendorRef><FullName>TaxCloud</FullName></TaxVendorRef>
        <SalesTaxReturnLineRef><FullName>Sales Tax Return Line Name</FullName></SalesTaxReturnLineRef>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemSalesTaxAdd>
    </ItemSalesTaxAddRq>
  XML
end

def update_xml_salestaxproduct
  <<~XML
    <ItemSalesTaxModRq requestID="12345">
      <ItemSalesTaxMod>
        <ListID>test salestax listid</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test salestax product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef> 
        <ItemDesc>This product is salestax</ItemDesc>
        <TaxRate>0.07</TaxRate>
        <TaxVendorRef><FullName>TaxCloud</FullName></TaxVendorRef>
        <SalesTaxReturnLineRef><FullName>Sales Tax Return Line Name</FullName></SalesTaxReturnLineRef>
      </ItemSalesTaxMod>
    </ItemSalesTaxModRq>
  XML
end

def update_xml_with_active_field_salestaxproduct
  <<~XML
    <ItemSalesTaxModRq requestID="12345">
      <ItemSalesTaxMod>
        <ListID>test salestax listid</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test salestax product</Name>
        <IsActive>true</IsActive>
      </ItemSalesTaxMod>
    </ItemSalesTaxModRq>
  XML
end
