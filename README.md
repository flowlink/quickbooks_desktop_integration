# Quickbooks Desktop Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com).

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send/Receive orders to Quickbooks
* Send/Receive invoices to Quickbooks
* Send/Receive sales receipts to Quickbooks
* Send/Receive customers to Quickbooks
* Send/Receive vendors to Quickbooks
* Send/Receives products (Inventory, NonInventory, Service, Discount, Sales Tax types) to Quickbooks
* Receives Inventory Assembly product types from Quickbooks
* Send/Receive purchase orders to Quickbooks
* Send payments to Quickbooks
* Send journal entries to Quickbooks
* Send returns to Quickbooks
* Send shipments to Quickbooks
* Set/Receives inventories to Quicbooks
* Receives inventories by site from Quicbooks

## Connection Parameters

The following parameters must be setup within [Flowlink](http://flowlink.io):

| Name | Value |
| :----| :-----|
| connection_id    | Used to uniquely identify connection(required) |
| origin           | Used to uniquely identify origin (required)    |

## Webhooks

The following webhooks are implemented:

* **add_orders**: Adds and Updates sales orders in QuickBooks
* **add_invoices**: Adds and Updates invoices in QuickBooks
* **add_salesreceipts**: Adds and Updates sales receipts in QuickBooks
* **add_customers**: Adds and Updates customers in QuickBooks
* **add_vendors**: Adds and Updates vendors in QuickBooks
* **add_products**: Adds and Updates products of type Inventory in QuickBooks
* **add_noninventoryproducts**: Adds and Updates products of type NonInventory in QuickBooks
* **add_serviceproducts**: Adds and Updates products of type Service in QuickBooks
* **add_discountproducts**: Adds and Updates products of type Discount in QuickBooks
* **add_salestaxproducts**: Adds and Updates products of type SalesTax in QuickBooks
* **add_purchaseorders**: Adds and Updates purchase orders in QuickBooks
* **add_payments**: Adds payments to QuickBooks
* **add_journals**: Adds and Updates journal entries in QuickBooks
* **add_inventories**: Adds inventories to QuickBooks
* **add_returns**: Adds returns to QuickBooks
* **add_shipments**: Adds shipments to QuickBooks

* **get_orders**: Gets orders from QuickBooks
* **get_invoices**: Gets invoices from QuickBooks
* **get_customers**: Gets customers from QuickBooks
* **get_vendors**: Gets vendors from QuickBooks
* **get_products**: Gets products of type Inventory from QuickBooks
* **get_inventoryproducts**: Gets products of type Inventory from QuickBooks
* **get_noninventoryproducts**: Gets products of type NonInventory from QuickBooks
* **get_serviceproducts**: Gets products of type Service from QuickBooks
* **get_discountproducts**: Gets products of type Discount from QuickBooks
* **get_salestaxproducts**: Gets products of type SalesTax from QuickBooks
* **get_inventoryassemblyproducts**: Gets products of type InventoryAssembly from QuickBooks
* **get_purchaseorders**: Gets purchase orders from QuickBooks
* **get_inventories**: Gets inventories from QuickBooks
* **get_inventorywithsites**: Gets inventories by Site from QuickBooks

### add_orders

The `add_orders` hook creates a Sales Order in QB for each order.
The following parameters are required when setting up a Flow with this webhook:

| Name | Value |
| :----| :-----|
| quickbooks_income_account       | QB account to use for order income  |
| quickbooks_cogs_account         | QB account to use for COGS |
| quickbooks_inventory_account    | QB account use for inventory |
| quickbooks_shipping_item        | QB item to use for shipping |
| quickbooks_discount_item        | QB item to use for discounts |
| quickbooks_tax_item             | QB item to use for taxes |
| quickbooks_use_tax_line_items   | If true, uses broken out taxes (if available) |
| quickbooks_customer_email       | If present, uses given email for all customers |
| quickbooks_auto_create_products | If checked, automatically create products for orders and shipments |
| use_amount_for_tax | If set to "1" then we use the "Amount" QBE field rather than "Rate" (used in Invoices too) |

## QBE Config and Refs

### Possible Config ONLY Values

| Name | Info |
| :----| :-----|
| quickbooks_customer_email | ?? |
| quickbooks_auto_create_products | ?? |
| quickbooks_auto_create_payments | ?? |
| origin | Should almost always be "flowlink" |
| connection_id | connection ID param|
| quickbooks_force_config | Set to 1 or "true" |
| return_all | Use to return all objects |
| receive | I think this gets set within the integration |
| flow | I think this gets set within the integration |

[Adding QBE Refs Readme](./QBE_REFS.md)

### Getting Products

You can retrieve specific product types by calling any of the following endpoints:

* /get_products (alias for /get_inventoryproducts)
* /get_noninventoryproducts
* /get_serviceproducts
* /get_salestaxproducts
* /get_discountproducts
* /get_inventoryassemblyproducts

### Adding Products

QBE has a few different product types that FlowLink allows you to add/mod/query

* inventory
* assembly
* noninventory
* salestax
* service
* discount

When **adding** noninventory or service products, the block of either SalesOrPurchase or SalesAndPurchase is required. To specify which block to use, you'll need to set the field to true. `sales_and_purchase = true` or `sales_or_purchase = true`. If both are set to true or neither are set, SalesAndPurchase is the default block.

When **modifying** noninventory or service products, these blocks are not required. If both `sales_and_purchase` and `sales_or_purchase` are set to true, SalesAndPurchase is still the default. If none are set, these blocks will be ignored.

Some products do not allow modifying of the SalesOrPurchase and SalesAndPurchase block, so be sure you can modify when you send the request.

## About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
