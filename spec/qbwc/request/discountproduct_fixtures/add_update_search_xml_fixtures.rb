def qbe_discountproduct_search_name
  <<~XML
    <ItemDiscountQueryRq requestID="12345">
      <MaxReturned>10000</MaxReturned>
      <NameRangeFilter>
        <FromName>My Awesome Product</FromName>
        <ToName>My Awesome Product</ToName>
      </NameRangeFilter>
    </ItemDiscountQueryRq>
  XML
end

def add_xml_discountproduct
  <<~XML
    <ItemDiscountAddRq requestID="12345">
      <ItemDiscountAdd>
        <Name>test discount product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ItemDesc>This product is discount</ItemDesc>
        <SalesTaxCodeRef><FullName>Tax</FullName></SalesTaxCodeRef>
        <DiscountRate>0.07</DiscountRate>
        <DiscountRatePercent>7</DiscountRatePercent>
        <AccountRef><FullName>Income Account</FullName></AccountRef>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemDiscountAdd>
    </ItemDiscountAddRq>
  XML
end

def update_xml_discountproduct
  <<~XML
    <ItemDiscountModRq requestID="12345">
      <ItemDiscountMod>
        <ListID>test discount listid</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test discount product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ItemDesc>This product is discount</ItemDesc>
        <SalesTaxCodeRef><FullName>Tax</FullName></SalesTaxCodeRef>
        <DiscountRate>0.07</DiscountRate>
        <DiscountRatePercent>7</DiscountRatePercent>
        <AccountRef><FullName>Income Account</FullName></AccountRef>
        <ApplyAccountRefToExistingTxns>true</ApplyAccountRefToExistingTxns>
      </ItemDiscountMod>
    </ItemDiscountModRq>
  XML
end

def update_xml_with_active_field_discountproduct
  <<~XML
    <ItemDiscountModRq requestID="12345">
      <ItemDiscountMod>
        <ListID>test discount listid</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test discount product</Name>
        <IsActive>true</IsActive>
      </ItemDiscountMod>
    </ItemDiscountModRq>
  XML
end
