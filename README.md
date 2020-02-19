# QuickBooks Desktop Integration

## Overview

[QuickBooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com).

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product.

This integration utilizes AmazonS3 buckets to store information. The integration renames data objects in S3 in a specific way that tracks the lifecycle of the data as we attempt to get/send it to/from QuickBooks Desktop.

The other connection to S3 is the [QuickBooks Web Connector](https://developer.intuit.com/app/developer/qbdesktop/docs/get-started/get-started-with-quickbooks-web-connector) (QBWC for short), a tool built by Inuit to allow the QuickBooks desktop client to access the internet and expose an API for developers. The Web Connector runs at an interval and hits the ./qbwc_endpoint.rb which handles the logic of determining what information we want to ask the QBWC to get for us from QuickBooks and what information we want to hand to it for adding, modifying, or deleting within QuickBooks.

Keep in mind that this 2 way connection to AmazonS3 means that the full connection between FlowLink and QuickBooks Desktop is asynchronous.

With this integration you can perform the following functions:

### Send Flows

* Send sales orders to QuickBooks
* Send sales receipts to QuickBooks
* Send returns to QuickBooks
* Send shipments to QuickBooks
* Send customers to QuickBooks
* Send products to QuickBooks (Inventory, Non-Inventory, Discount, Sales Tax, and Service types)
* Create Bills (based off of a purchase order's lifecycle) in QuickBooks
* Send Journal Entries to QuickBooks
* Send Payments to QuickBooks
* Send Purchase Orders to QuickBooks
* Send Vendors to QuickBooks
* Set inventories in QuickBooks

### Get Flows

* Get sales orders from QuickBooks
* Get sales receipts from QuickBooks
* Get returns from QuickBooks
* Get shipments from QuickBooks
* Get customers from QuickBooks
* Get products from QuickBooks (Inventory, Non-Inventory, Discount, Sales Tax, and Service types)
* Get Bills from QuickBooks
* Get Journal Entries from QuickBooks
* Get Payments from QuickBooks
* Get Purchase Orders from QuickBooks
* Get Vendors from QuickBooks
* Get inventories from QuickBooks

## Two Phase Workflows

Some **Send** workflows are two phase workflows. This means that it requires two phases of interaction with the QBWC to handle adding/modifying the data in QuickBooks Desktop.

Adding a customer to QuickBooks Desktop is not a two phase workflow. We just need to check if the customer exists and if it does not, we create the customer. If the customer does exists we modify the existing customer. The customer object does not depend on any other objects.

Adding a Sales Order *is* an example of a two phase workflow. A Sales Order depends on other objects in QBE. It **contains** other objects inside of it (Customer, Products, etc)

When we attempt to add a Sales Order, we need to first check if the line items on the order already exist as items in QuickBooks. We also need to check if the customer on the sales order exists in QuickBooks.
Then, we can check on the Sales Order in QuickBooks and create/modify depending on if it exists already.

## Connection Parameters

The following parameters must be setup within [Flowlink](http://flowlink.io):

| Name | Value |
| :----| :-----|
| connection_id    | Used to uniquely identify connection(required) |
| origin           | Used to uniquely identify origin (required)    |

## QBE Config and Refs

### Possible Config ONLY Values

| Name | Info | Required |
| :----| :-----| :-----|
| quickbooks_customer_email | If present, uses given email for all customers | False |
| quickbooks_auto_create_products | Set to 1 to have the workflow create products if they do not exist in QBE | False |
| quickbooks_auto_create_payments | Set to 1 to have the workflow create the payments if they do not exist in QBE | False |
| origin | Should almost always be "flowlink" | True |
| connection_id | connection ID param| True |
| payload_type | The type of object that is being sent to QBE. Lowercase, without underscores, and singular | True |
| quickbooks_force_config | Set to 1 or "true" | False |
| return_all | Use to return all objects | False |
| receive | I think this gets set within the integration | ? |
| flow | I think this gets set within the integration | ? |

[Adding QBE Refs Readme](./QBE_REFS.md)

## Webhooks

The following webhooks are implemented:

* **add_orders**: Adds Sales Orders to QuickBooks
* **add_salesreceipts**: Adds Sales Receipts to QuickBooks
* **add_returns**: Adds Returns to QuickBooks
* **add_shipments**: Adds Shipments to QuickBooks
* **add_customers**: Adds Customers to QuickBooks
* **add_products**: Adds Inventory Products to QuickBooks
* **add_noninventoryproducts**: Adds Non-Inventory Products to QuickBooks
* **add_serviceproducts**: Adds Service Products to QuickBooks
* **add_salestaxproducts**: Adds Sales Tax Products to QuickBooks
* **add_discountproducts**: Adds Discount Products to QuickBooks
* **add_inventories**: Adds Inventories to QuickBooks
* **add_payments**: Adds Payments to QuickBooks (and links with an associated transaction)
* **add_purchaseorders**: Adds Purchase Orders to QuickBooks
* **add_invoices**: Adds Invoices to QuickBooks
* **add_journals**: Adds Journal Entries to QuickBooks
* **add_vendors**: Adds Vendors to QuickBooks
* **add_bills**: Adds Bills to QuickBooks
* **cancel_order**: Cancels an Order in QuickBooks
* **get_products**: Gets Products from QuickBooks (either all types or can filter out types)
* **get_inventories**: Gets Inventories from QuickBooks
* **get_inventory**: Gets a single Product's Inventory count from QuickBooks
* **get_invoices**: Gets Invoices from QuickBooks
* **get_purchaseorders**: Gets Purchase Orders from QuickBooks
* **get_customers**: Gets Customers from QuickBooks
* **get_orders**: Gets Sales Orders from QuickBooks
* **get_vendors**: Gets Vendors from QuickBooks
* **get_noninventoryproducts**: Gets Non Inventory Products from QuickBooks
* **get_serviceproducts**: Gets Service Products from QuickBooks
* **get_salestaxproducts**: Gets Salestax Products from QuickBooks
* **get_discountproducts**: Gets Discount Products from QuickBooks
* **get_inventoryproducts**: Gets Inventory Products from QuickBooks

### add_orders

The `add_orders` hook creates a Sales Order in QB for each order.
The following parameters are required when setting up a Flow with this webhook:

| Name | Value | Required |
| :----| :-----| :-----|
| quickbooks_income_account | QB GL account name to to use for transaction income | True |
| quickbooks_cogs_account | QB GL account name to to use for COGS | False |
| quickbooks_inventory_account | QB GL account name to use for inventory | False |
| quickbooks_shipping_item | QB item to use for shipping | True |
| quickbooks_discount_item | QB item to use for discounts | True |
| quickbooks_tax_item | QB item to use for taxes | True |
| quickbooks_use_tax_line_items | If true, uses broken out taxes (if available) | False |
| quickbooks_customer_email | If present, uses given email for all customers | False |
| quickbooks_auto_create_products | If checked, automatically create products for orders and shipments | False |
| use_amount_for_tax | If set to "1" then we use the "Amount" QBE field rather than "Rate" (used in Invoices too) | False |

Notes:

* We use the 'placed_on' field to set the Transaction date in QBE. This needs to be a valid date string otherwise an exception will be raised

### add_salesreceipts

The `add_salesreceipts` hook creates a Sales Receipt in QB for each order.
The following parameters are required when setting up a Flow with this webhook:

| Name | Value | Required |
| :----| :-----| :-----|
| quickbooks_income_account | QB GL account name to to use for transaction income | True |
| quickbooks_cogs_account | QB GL account name to to use for COGS | False |
| quickbooks_inventory_account | QB GL account name to use for inventory | False |
| quickbooks_shipping_item | QB item to use for shipping | True |
| quickbooks_discount_item | QB item to use for discounts | True |
| quickbooks_tax_item | QB item to use for taxes | True |
| quickbooks_use_tax_line_items | If true, uses broken out taxes (if available) | False |
| quickbooks_customer_email | If present, uses given email for all customers | False |
| quickbooks_auto_create_products | If checked, automatically create products for orders and shipments | False |
| use_amount_for_tax | If set to "1" then we use the "Amount" QBE field rather than "Rate" (used in Invoices too) | False |

Notes:

* We use the 'placed_on' field to set the Transaction date in QBE. This needs to be a valid date string otherwise an exception will be raised

### add_returns

Todo - add info here...

### add_shipments

Todo - add info here...

### add_customers

Todo - add info here...

### add_products

Todo - add info here...

### add_noninventoryproducts

Todo - add info here...

### add_serviceproducts

Todo - add info here...

### add_salestaxproducts

Todo - add info here...

### add_discountproducts

Todo - add info here...

### add_inventories

Todo - add info here...

### add_payments

Todo - add info here...

### add_purchaseorders

Todo - add info here...

### add_invoices

Todo - add info here...

### add_journals

Todo - add info here...

### add_vendors

Todo - add info here...

### add_bills

Todo - add info here...

### cancel_order

Todo - add info here...

### Get Products

You can retrieve products from QBE in a couple different ways.

You can retrieve specific product types by calling any of the following endpoints:

* /get_noninventoryproducts
* /get_serviceproducts
* /get_salestaxproducts
* /get_discountproducts
* /get_inventoryproducts

---

You can also get all products by calling `/get_products` and it will return all possible types (inventory, non-inventory, assembly, service, sales tax, discount)

---

You can also call `/get_products` and specify a config value - see below

  ```ruby
  # Accepted values in the array are shown below
  # Non valid inputs will be ignored

  config[:quickbooks_specify_products] = "[\"inventory\", \"assembly\", \"noninventory\", \"salestax\", \"service\", \"discount\"]"

  # NOTE: Be sure to escape the string values of each item in the "array"
```

### get_inventories

Todo - add info here...

### get_inventory

Todo - add info here...

### get_invoices

Todo - add info here...

### get_purchaseorders

Todo - add info here...

### get_customers

Todo - add info here...

### get_orders

Todo - add info here...

### get_vendors

Todo - add info here...

### get_noninventoryproducts

Todo - add info here...

### get_serviceproducts

Todo - add info here...

### get_salestaxproducts

Todo - add info here...

### get_discountproducts

Todo - add info here...

### get_inventoryproducts

Todo - add info here...

## About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
