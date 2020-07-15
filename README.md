# Quickbooks Desktop Integration

## Get it Running

You can run the integration locally:

```sh
scripts/run_local.sh
```

The script accepts further arguments for docker-compose like `build`, `up`, etc

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
* Run a "healthcheck" to ensure the QBWC is still contacting the integration

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
* **add_creditmemos**: Adds credit memos to QuickBooks (and apply them to an invoice)

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

* **get_notifications**: Retrieves succes and failure notifications from previous requests
* **healthcheck**: Runs a check to see when the last time the QBWC connected with this integration. Returns an error if the amount of time is past a certain threshold

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
| quickbooks_use_customer_object | If set to "1" then we use the `customer` key (must be a hash) on the parent object rather than letting the qbe integration build the hash |
| quickbooks_use_vendor_object | If set to "1" then we use the `vendor` key (must be a hash) on the parent object rather than letting the qbe integration build the hash |
| quickbooks_use_product_objects | If set to "1" then we use the `products` key (must be an array of hashes) on the parent object rather than letting the qbe integration build the array |

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
| health_check_threshold_in_minutes | Minute threshold to determine if the QBWC is failing it's healthcheck or not |

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

### Adding Credit Memos

You can add a credit memo easily by using the /add_creditmemos endpoint. This will create the credit memo, but won't apply it.

You can automatically apply it to an invoice in QBE by utilizing the `other` field in the QBXML. `other` is used for:

* Storing the invoice ID
* Storing a dynamic payment method (If not given, defaults to "CASH")

These values should be separated by 3 colons (:::)

If you had a credit memo to be applied to the invoice with the ID: 192839 and you wanted the payment method to be "Credit Card", the payload should be:

```ruby
creditmemo: {
  id: 1209102912,
  other: "192839:::Credit Card",
  # More fields...
}
```

### Running the Health Check

FlowLink relies on the QuickBooks Web Connector (QBWC) to connect with QuickBooks Enterprise applications, but FlowLink has no development control over the QBWC. So when the QBWC either gets closed or the auto-run gets turned off, FlowLink is not automatically notified.
To ensure that clients are notified quickly if this happens, you can use the /healthcheck endpoint to determine if the QBWC is still running. The /healthcheck endpoint checks a file in S3 named /settings/healthcheck.json. This file stores the timestamp of the last time the QBWC made a request to the integration. The timestamp is updated when the QBWC makes a request to the integration (On both send_request_xml and receive_response_xml but not any of the other QBWC endpoints). The /healthcheck endpoint checks the timestamp using the following formula:

```ruby
now = Time.now.utc

# Default the last contact to right now
last_contact = healthcheck_settings[:qbwc_last_contact_at] || now.to_s

# Calculate the time difference in minutes from now and the last contact with the QBWC
difference_in_minutes = (now - Time.parse(last_contact).utc) / 60.0

# Calculate the threshold for determining if we should consider the QBWC as failing the healthcheck
threshold = config[:health_check_threshold_in_minutes] || DEFAULT_HEALTHCHECK_THRESHOLD

threshold.to_i < difference_in_minutes
```

The integration will automatically set `qbwc_last_contact_at` as the QBWC runs. The default threshold (in minutes) is 5. To set your own threshold, use the `health_check_threshold_in_minutes` config parameter.

Some things to note:

1. If the QBWC goes down, FlowLink will continue to generate errors until the situation is rectified
2. If the QBWC is set to autorun at a higher than normal rate, please consider this when setting the `health_check_threshold_in_minutes` parameter

## Specs

### Running Specs

You can run all the specs for the project by using the `run_tests.sh` script. The script allows you to append further commands ("--seed 1234", a specific test to run only instead of the full suite, etc)

### Specs and AWS config

[VCR](https://github.com/vcr/vcr) is utilized for many of the specs while some specs simply stub out AWS connections. It's important to explicitly dictate if you want to stub out AWS or not. The tests run randomly and the global setting for stubbing AWS connections can be turned on and off per test, so it's not guaranteed to be a specific value before each test is run.
You can explicitly set the value per test by adding `Aws.config[:stub_responses] = <boolean>` before the test runs, or you can set the value for the entire file by adding the following at the top of your specs for that file:

```ruby
before(:each) do
  Aws.config[:stub_responses] = <boolean>
end
```

## About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
