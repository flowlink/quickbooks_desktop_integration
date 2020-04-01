def qbe_noninventoryproduct_search_name
  <<~XML
    <ItemNonInventoryQueryRq requestID="12345">
      <MaxReturned>10000</MaxReturned>
      <NameRangeFilter>
        <FromName>My Awesome Product</FromName>
        <ToName>My Awesome Product</ToName>
      </NameRangeFilter>
    </ItemNonInventoryQueryRq>
  XML
end

def add_xml_sandp
  <<~XML
    <ItemNonInventoryAddRq requestID="12345">
      <ItemNonInventoryAdd>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesAndPurchase>
          <SalesDesc>This product is non inventory</SalesDesc>
          <SalesPrice>20.00</SalesPrice>
          <IncomeAccountRef><FullName>Income Account</FullName></IncomeAccountRef>
          <PurchaseDesc>This product is non inventory and available for purchase</PurchaseDesc>
          <PurchaseCost>5.00</PurchaseCost>
          <PurchaseTaxCodeRef><FullName>standard tax</FullName></PurchaseTaxCodeRef>
          <ExpenseAccountRef><FullName>Expense Account</FullName></ExpenseAccountRef>
          <PrefVendorRef><FullName>Sully's Hot Dog Stand</FullName></PrefVendorRef>
        </SalesAndPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryAdd>
    </ItemNonInventoryAddRq>
  XML
end

def add_xml_sorp_with_percent
  <<~XML
    <ItemNonInventoryAddRq requestID="12345">
      <ItemNonInventoryAdd>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchase>
          <Desc>This product is non inventory</Desc>
          <PricePercent>100</PricePercent>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
        </SalesOrPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryAdd>
    </ItemNonInventoryAddRq>
  XML
end

def add_xml_sorp_without_percent
  <<~XML
    <ItemNonInventoryAddRq requestID="12345">
      <ItemNonInventoryAdd>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchase>
          <Desc>This product is non inventory</Desc>
          <Price>20.00</Price>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
        </SalesOrPurchase>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryAdd>
    </ItemNonInventoryAddRq>
  XML
end

def update_xml_sandp
  <<~XML
    <ItemNonInventoryModRq requestID="12345">
      <ItemNonInventoryMod>
        <ListID>test noninv product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesAndPurchaseMod>
          <SalesDesc>This product is non inventory</SalesDesc>
          <SalesPrice>20.00</SalesPrice>
          <IncomeAccountRef><FullName>Income Account</FullName></IncomeAccountRef>
          <ApplyIncomeAccountRefToExistingTxns>true</ApplyIncomeAccountRefToExistingTxns>
          <PurchaseDesc>This product is non inventory and available for purchase</PurchaseDesc>
          <PurchaseCost>5.00</PurchaseCost>
          <PurchaseTaxCodeRef><FullName>standard tax</FullName></PurchaseTaxCodeRef>
          <ExpenseAccountRef><FullName>Expense Account</FullName></ExpenseAccountRef>
          <ApplyExpenseAccountRefToExistingTxns>true</ApplyExpenseAccountRefToExistingTxns>
          <PrefVendorRef><FullName>Sully's Hot Dog Stand</FullName></PrefVendorRef>
        </SalesAndPurchaseMod>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryMod>
    </ItemNonInventoryModRq>
  XML
end

def update_xml_sorp_without_percent
  <<~XML
    <ItemNonInventoryModRq requestID="12345">
      <ItemNonInventoryMod>
        <ListID>test noninv product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchaseMod>
          <Desc>This product is non inventory</Desc>
          <Price>20.00</Price>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
          <ApplyAccountRefToExistingTxns>true</ApplyAccountRefToExistingTxns>
        </SalesOrPurchaseMod>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryMod>
    </ItemNonInventoryModRq>
  XML
end

def update_xml_sorp_with_percent
  <<~XML
    <ItemNonInventoryModRq requestID="12345">
      <ItemNonInventoryMod>
        <ListID>test noninv product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test noninv product</Name>
        <BarCode>
          <BarCodeValue>0001910191</BarCodeValue>
          <AssignEvenIfUsed>true</AssignEvenIfUsed>
          <AllowOverride>false</AllowOverride>
        </BarCode>
        <IsActive>true</IsActive>
        <ParentRef><FullName>GermanCars:Mercedes-Benz</FullName></ParentRef>
        <ClassRef><FullName>Class1:Class2</FullName></ClassRef>
        <ManufacturerPartNumber>partnumber123</ManufacturerPartNumber>
        <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
        <ForceUOMChange>true</ForceUOMChange>
        <IsTaxIncluded>false</IsTaxIncluded>
        <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
        <SalesOrPurchaseMod>
          <Desc>This product is non inventory</Desc>
          <PricePercent>100</PricePercent>
          <AccountRef><FullName>Income Account</FullName></AccountRef>
          <ApplyAccountRefToExistingTxns>true</ApplyAccountRefToExistingTxns>
        </SalesOrPurchaseMod>
        <ExternalGUID>109389220</ExternalGUID>
      </ItemNonInventoryMod>
    </ItemNonInventoryModRq>
  XML
end

def update_xml_with_active_field
  <<~XML
    <ItemNonInventoryModRq requestID="12345">
      <ItemNonInventoryMod>
        <ListID>test noninv product</ListID>
        <EditSequence>19209j3od-d9292</EditSequence>
        <Name>test noninv product</Name>
        <IsActive>true</IsActive>
      </ItemNonInventoryMod>
    </ItemNonInventoryModRq>
  XML
end
