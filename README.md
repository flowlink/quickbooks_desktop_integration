# Quickbooks Desktop Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com).

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send orders to Quickbooks
* Send returns to Quickbooks
* Send shipments to Quickbooks
* Send customers to Quickbooks
* Send/Receives products to Quickbooks
* Set/Receives inventories to Quicbooks

## Connection Parameters

The following parameters must be setup within [Flowlink](http://flowlink.io):

| Name | Value |
| :----| :-----|
| connection_id    | Used to uniquely identify connection(required) |
| origin           | Used to uniquely identify origin (required)    |

## Webhooks

The following webhooks are implemented:

* **add_orders**: Adds orders to QuickBooks
* **add_returns**: Adds returns to QuickBooks
* **add_shipments**: Adds shipments to QuickBooks
* **add_customers**: Adds customers to QuickBooks
* **add_products**: Adds products to QuickBooks
* **add_inventories**: Adds inventories to QuickBooks
* **get_products**: Gets products from QuickBooks
* **get_inventories**: Gets inventories from QuickBooks

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

  config[:quickbooks_specify_products] = "[\"inventory\", \"assembly\", \"noninventory\", \"salestax\", \"service\", \"discount\", \"adjustment\"]"

  # NOTE: Be sure to escape the string values of each item in the "array"
```

## About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
