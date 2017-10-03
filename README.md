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
| quickbooks_income_account     | QB account to use for order income  |
| quickbooks_cogs_account       | QB account to use for COGS |
| quickbooks_inventory_account  | QB account use for inventory |
| quickbooks_shipping_item      | QB item to use for shipping |
| quickbooks_discount_item      | QB item to use for discounts |
| quickbooks_tax_item           | QB item to use for taxes |
| quickbooks_use_tax_line_items | If true, uses broken out taxes (if available) |

# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
