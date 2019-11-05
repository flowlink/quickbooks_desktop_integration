# Adding QBE Refs by Workflow

## Tips

- `object` refers to the actual payload object (order, customer, etc)
- `config` refers to the params sent by FlowLink
- Some objects have the functionality to use either `object` or `config` and some have one or the other
- Use FlowLink transforms to set these values

### Products

  ```ruby
  IncomeAccountRef: object['income_account'] || config['quickbooks_income_account']
  COGSAccountRef: object['cogs_account'] || config['quickbooks_cogs_account']
  AssetAccountRef: object['inventory_account'] || config['quickbooks_inventory_account']
  UnitOfMeasureSetRef: object['unit_of_measure'] (object ONLY)
  ```

### Non Inventory Products

  ```ruby
  IncomeAccountRef: "income_account" (object || config)
  PurchaseTaxCodeRef: "purchase_tax_code_name" (object || config)
  ExpenseAccountRef: "expense_account" (object || config)
  PrefVendorRef: "preferred_vendor_name" (object || config)
  ClassRef: "class_name" (object || config)
  ParentRef: "parent_name" (object || config)
  UnitOfMeasureSetRef: "unit_of_measure" (object || config)
  SalesTaxCodeRef: "sales_tax_code_name" (object || config)
  AccountRef: "account_name" (object || config)
  ```

### Customers

  ```ruby
  ClassRef: "class_name" (object || config)
  ParentRef: "parent_name" (object || config)
  CustomerTypeRef: "customer_type_name" (object || config)
  TermsRef: "terms" (object || config)
  SalesRepRef: "sales_rep_name" (object || config)
  SalesTaxCodeRef: "sales_tax_code_name" (object || config)
  ItemSalesTaxRef: "item_sales_tax_name" (object || config)
  PreferredPaymentMethodRef: "preferred_payment_method_name" (object || config)
  JobTypeRef: "job_type_name" (object || config)
  PriceLevelRef: "price_level_name" (object || config)
  CurrencyRef: "currency_name" (object || config)
  ```

### Vendors

  ```ruby
  ClassRef: "class_name" (object || config)
  BillingRateRef: "billing_rate_name" (object || config)
  VendorTypeRef: "vendor_type_name" (object || config)
  TermsRef: "terms" (object || config)
  SalesTaxCodeRef: "sales_tax_code_name" (object || config)
  SalesTaxReturnRef: "sales_tax_return_name" (object || config)
  TaxOnPurchasesAccountRef: "tax_on_purchases_account_name" (object || config)
  TaxOnSalesAccountRef: "tax_on_sales_account_name" (object || config)
  CurrencyRef: "currency_name" (object || config)
  ```

### Invoice

  ```ruby
  SalesRepRef: object['sales_rep']['name'] (object ONLY)
  CustomerRef: object['customer']['list_id'] || object['customer']['name'] (object ONLY)
  ClassRef: "class_name" (object ONLY)
  ClassRef: "class_name" (object ONLY - line item)
  ItemRef: "product_id" (object ONLY - line item)
  InventorySiteRef: "inventory_site_name" (object ONLY - line item)
  SalesTaxCodeRef: "tax_code_id" (object ONLY - line item)
  ```

### Orders

  ```ruby
  CustomerRef: object['customer']['list_id'] || object['customer']['name'] (object ONLY)
  ClassRef: "class_name" (object ONLY)
  ClassRef: "class_name" (object ONLY - line item)
  ItemRef: "product_id" (object ONLY - line item)
  SalesTaxCodeRef: "tax_code_id" (object ONLY - line item)
  ```

### Payments

  ```ruby
  CustomerRef: object['customer']['name'] (object ONLY)
  PaymentMethodRef: "payment_method" (object ONLY)
  ```

### Purchase Orders

  ```ruby
  VendorRef: object['supplier']['name'] (object ONLY)
  ClassRef: "class_name" (object ONLY)
  ClassRef: "class_name" (object ONLY - line item)
  ItemRef: "product_id" (object ONLY - line item)
  SalesTaxCodeRef: "tax_code_id" (object ONLY - line item)
  ```

### Returns

  ```ruby
  CustomerRef: "email" (object ONLY)
  PaymentMethodRef: object['refunds'].to_a.first['payment_method'] (object ONLY)
  DepositToAccountRef: quickbooks_deposit_account (config ONLY)
  ItemRef: "product_id" (object ONLY - line item)
  SalesTaxCodeRef: "tax_code_id" (object ONLY - line item)
  ```

### Sales Receipts

  ```ruby
  CustomerRef: object['customer']['name'] (object ONLY)
  ClassRef: "class_name" (object ONLY)
  ClassRef: "class_name" (object ONLY - line item)
  ItemRef: "product_id" (object ONLY - line item)
  InventorySiteRef: "inventory_site_name" (object ONLY - line item)
  SalesTaxCodeRef: "tax_code_id" (object ONLY - line item)
  ```

### Shipments

  ```ruby
  CustomerRef: "email" (object ONLY)
  ItemRef(Modify Only): See Below
    Adjustment Name == shipping_discount
    - object['shipping_discount_item'] || params['quickbooks_shipping_discount_item']
    Adjustment Name == discount
    - object['discount_item'] || params['quickbooks_discount_item']
    Adjustment Name == shipping
    - object['shipping_item'] || params['quickbooks_shipping_item']
    Adjustment Name == tax
    - object['tax_item'] || params['quickbooks_tax_item']
  ```

### Inventories

  ```ruby
  AccountRef: "quickbooks_income_account" (config ONLY)
  ```

### Adjustments

  ```ruby
  AccountRef: account(adjustment, params)
    def account(adjustment, params)
      if adjustment['id'].downcase.match(/discount/)
        params['quickbooks_other_charge_discount_account']
      elsif adjustment['id'].downcase.match(/shipping/)
        params['quickbooks_other_charge_shipping_account']
      else
        params['quickbooks_other_charge_tax_account']
      end
    end
  ```