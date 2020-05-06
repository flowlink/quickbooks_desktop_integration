def qbe_product_search_name
  <<~XML
    <ItemInventoryQueryRq requestID="12345">
      <MaxReturned>10000</MaxReturned>
      <NameRangeFilter>
        <FromName>My Awesome Product</FromName>
        <ToName>My Awesome Product</ToName>
      </NameRangeFilter>
    </ItemInventoryQueryRq>
  XML
end

def qbe_product_search_id
  <<~XML
    <ItemInventoryQueryRq requestID="12345">
      <ListID>test product listid</ListID>
    </ItemInventoryQueryRq>
  XML
end

def add_xml
  <<~XML
    <ItemInventoryAddRq requestID="12345">
      <ItemInventoryAdd>
        #{product_xml(false)}
      </ItemInventoryAdd>
    </ItemInventoryAddRq>
  XML
end

def update_xml
  <<~XML
    <ItemInventoryModRq requestID="12345">
        <ItemInventoryMod>
          <ListID>FE1221</ListID>
          <EditSequence>19209j3od-d9292</EditSequence>
          #{product_xml(true)}
        </ItemInventoryMod>
    </ItemInventoryModRq>
  XML
end

def product_xml(is_mod)
  force_uom_change = is_mod ? "<ForceUOMChange>#{true}</ForceUOMChange>" : ""
  apply_income_account_ref_to_existing_txns = is_mod ? "<ApplyIncomeAccountRefToExistingTxns>#{true}</ApplyIncomeAccountRefToExistingTxns>" : ""
  apply_cogs_account_ref_to_existing_txns = is_mod ? "<ApplyCOGSAccountRefToExistingTxns>#{true}</ApplyCOGSAccountRefToExistingTxns>" : ""
  quantity = is_mod ? "" : "<QuantityOnHand>#{1000}</QuantityOnHand>"
  total_value = is_mod ? "" : "<TotalValue>#{20000}</TotalValue>"
  inventory_date = is_mod ? "" : "<InventoryDate>2019-09-24T17:24:16-05:00</InventoryDate>"
  guid = is_mod ? "" : "<ExternalGUID>0120i-f23f23-f2im39-199f33m993mf</ExternalGUID>"
  
  <<~XML
    <Name>FE1221</Name>
    <BarCode>
      <BarCodeValue>3990239-399239</BarCodeValue>
      <AssignEvenIfUsed>true</AssignEvenIfUsed>
      <AllowOverride>false</AllowOverride>
    </BarCode>
    <IsActive>true</IsActive>
    <ClassRef><FullName>my class</FullName></ClassRef>
    <ParentRef><FullName>my parent</FullName></ParentRef>
    <ManufacturerPartNumber>man_part-num</ManufacturerPartNumber>
    <UnitOfMeasureSetRef><FullName>feet</FullName></UnitOfMeasureSetRef>
    #{force_uom_change}
    <IsTaxIncluded>false</IsTaxIncluded>
    <SalesTaxCodeRef><FullName>tax</FullName></SalesTaxCodeRef>
    <SalesDesc>Crazy product description</SalesDesc>
    <SalesPrice>155.00</SalesPrice>
    <IncomeAccountRef><FullName>Income Acct</FullName></IncomeAccountRef>
    #{apply_income_account_ref_to_existing_txns}
    <PurchaseDesc>Crazy purchase description</PurchaseDesc>
    <PurchaseCost>62.00</PurchaseCost>
    <PurchaseTaxCodeRef><FullName>purchase tax</FullName></PurchaseTaxCodeRef>
    <COGSAccountRef><FullName>Cost of Goods</FullName></COGSAccountRef>
    #{apply_cogs_account_ref_to_existing_txns}
    <PrefVendorRef><ListID>1029203902</ListID></PrefVendorRef>
    <AssetAccountRef><FullName>Inventory Asset</FullName></AssetAccountRef>
    <ReorderPoint>99</ReorderPoint>
    <Max>10000</Max>
    #{quantity}
    #{total_value}
    #{inventory_date}
    #{guid}
  XML
end