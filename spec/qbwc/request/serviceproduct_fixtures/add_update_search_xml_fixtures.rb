def qbe_serviceproduct_search_name
  <<~XML
    <ItemServiceQueryRq requestID="12345">
      <MaxReturned>10000</MaxReturned>
      <NameRangeFilter>
        <FromName>My Awesome Product</FromName>
        <ToName>My Awesome Product</ToName>
      </NameRangeFilter>
    </ItemServiceQueryRq>
  XML
end

def add_xml_sandp_serviceproduct
  <<~XML
    <ItemServiceAddRq requestID="12345">
      <ItemServiceAdd>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesAndPurchase>
          <SalesDesc>This product is service</SalesDesc>
          <SalesPrice>20.00</SalesPrice>
          <IncomeAccountRef><FullName>Income Account</FullName></IncomeAccountRef>
          <PurchaseDesc>This product is service and available for purchase</PurchaseDesc>
          <PurchaseCost>5.00</PurchaseCost>
          <PurchaseTaxCodeRef><FullName>standard tax</FullName></PurchaseTaxCodeRef>
          <ExpenseAccountRef><FullName>Expense Account</FullName></ExpenseAccountRef>
          <PrefVendorRef><FullName>Sully's Hot Dog Stand</FullName></PrefVendorRef>
        </SalesAndPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemServiceAdd>
    </ItemServiceAddRq>
  XML
end

def add_xml_sorp_with_percent_serviceproduct
  <<~XML
    <ItemServiceAddRq requestID="12345">
      <ItemServiceAdd>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchase>
          <Desc>This product is service</Desc>
          <PricePercent>100</PricePercent>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
        </SalesOrPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemServiceAdd>
    </ItemServiceAddRq>
  XML
end

def add_xml_sorp_without_percent_serviceproduct
  <<~XML
    <ItemServiceAddRq requestID="12345">
      <ItemServiceAdd>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchase>
          <Desc>This product is service</Desc>
          <Price>20.00</Price>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
        </SalesOrPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemServiceAdd>
    </ItemServiceAddRq>
  XML
end

def update_xml_sandp_serviceproduct
  <<~XML
    <ItemServiceModRq requestID="12345">
      <ItemServiceMod>
        <ListID>test service product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesAndPurchaseMod>
          <SalesDesc>This product is service</SalesDesc>
          <SalesPrice>20.00</SalesPrice>
          <IncomeAccountRef><FullName>Income Account</FullName></IncomeAccountRef>
          <ApplyIncomeAccountRefToExistingTxns>true</ApplyIncomeAccountRefToExistingTxns>
          <PurchaseDesc>This product is service and available for purchase</PurchaseDesc>
          <PurchaseCost>5.00</PurchaseCost>
          <PurchaseTaxCodeRef><FullName>standard tax</FullName></PurchaseTaxCodeRef>
          <ExpenseAccountRef><FullName>Expense Account</FullName></ExpenseAccountRef>
          <ApplyExpenseAccountRefToExistingTxns>true</ApplyExpenseAccountRefToExistingTxns>
          <PrefVendorRef><FullName>Sully's Hot Dog Stand</FullName></PrefVendorRef>
        </SalesAndPurchaseMod>
      </ItemServiceMod>
    </ItemServiceModRq>
  XML
end

def update_xml_sorp_without_percent_serviceproduct
  <<~XML
    <ItemServiceModRq requestID="12345">
      <ItemServiceMod>
        <ListID>test service product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchaseMod>
          <Desc>This product is service</Desc>
          <Price>20.00</Price>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
          <ApplyAccountRefToExistingTxns>true</ApplyAccountRefToExistingTxns>
        </SalesOrPurchaseMod>
      </ItemServiceMod>
    </ItemServiceModRq>
  XML
end

def update_xml_sorp_with_percent_serviceproduct
  <<~XML
    <ItemServiceModRq requestID="12345">
      <ItemServiceMod>
        <ListID>test service product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test service product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchaseMod>
          <Desc>This product is service</Desc>
          <PricePercent>100</PricePercent>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
          <ApplyAccountRefToExistingTxns>true</ApplyAccountRefToExistingTxns>
        </SalesOrPurchaseMod>
      </ItemServiceMod>
    </ItemServiceModRq>
  XML
end

def update_xml_with_active_field_serviceproduct
  <<~XML
    <ItemServiceModRq requestID="12345">
      <ItemServiceMod>
        <ListID>test service product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test service product</Name>
        <IsActive>true</IsActive>
      </ItemServiceMod>
    </ItemServiceModRq>
  XML
end
