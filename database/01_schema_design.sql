/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 01_schema_design.sql
Purpose: Document the relational database schema design
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

SOURCE DATASET OVERVIEW
-------------------------------------------------------------------------------

The original dataset is provided as a single transactional table.

Original columns:

- InvoiceNo
- StockCode
- Description
- Quantity
- InvoiceDate
- UnitPrice
- CustomerID
- Country

Each row represents one product line within an invoice.

This means that the same invoice can appear multiple times when a customer buys
multiple products in the same order.

Example:

InvoiceNo | StockCode | Description | Quantity | InvoiceDate | UnitPrice | CustomerID | Country

The goal of this step is to transform the single raw transactional table into a
relational database model that better represents a real-world e-commerce system.

===============================================================================
RELATIONAL DATABASE DESIGN
===============================================================================

The database will be organized into the following main tables:

1. raw_online_retail
2. customers
3. products
4. orders
5. order_items
6. payments
7. shipments

The first table stores the original imported data.
The other tables represent the cleaned and structured relational model.

===============================================================================
1. raw_online_retail
===============================================================================

Purpose:
Stores the original dataset exactly as imported from the source file.

This table is useful for:
- preserving the original raw data;
- performing data quality checks;
- comparing cleaned data with source data;
- reproducing transformations.

Columns:

- invoice_no
- stock_code
- description
- quantity
- invoice_date
- unit_price
- customer_id
- country

Source mapping:

invoice_no    <- InvoiceNo
stock_code    <- StockCode
description   <- Description
quantity      <- Quantity
invoice_date  <- InvoiceDate
unit_price    <- UnitPrice
customer_id   <- CustomerID
country       <- Country

Notes:
- Cancelled invoices may be identified by invoice numbers starting with 'C'.
- Negative quantities may indicate returns or cancellations.
- Missing customer IDs must be investigated.
- Unit prices less than or equal to zero should be checked before analysis.

===============================================================================
2. customers
===============================================================================

Purpose:
Stores unique customer-level information.

Grain:
One row per customer.

Columns:

- customer_id
- country

Primary key:
- customer_id

Source:
- customer_id comes from CustomerID
- country comes from Country

Business logic:
Each customer should appear once in this table.

Potential issue:
If a customer appears in more than one country, this should be investigated
during data quality checks.

===============================================================================
3. products
===============================================================================

Purpose:
Stores unique product-level information.

Grain:
One row per product.

Columns:

- product_id
- product_name
- standard_unit_price
- product_cost

Primary key:
- product_id

Source:
- product_id comes from StockCode
- product_name comes from Description
- standard_unit_price is derived from UnitPrice
- product_cost will be simulated for profitability analysis

Business logic:
Each unique StockCode should represent one product.

Potential issue:
The same product code may appear with different descriptions or different prices.
This should be investigated during data quality checks.

The product_cost field does not exist in the original dataset.
It will be simulated later to support:
- gross profit analysis;
- margin analysis;
- product profitability analysis;
- dashboard KPIs.

===============================================================================
4. orders
===============================================================================

Purpose:
Stores order-level information.

Grain:
One row per invoice/order.

Columns:

- order_id
- customer_id
- order_date
- order_status
- country

Primary key:
- order_id

Foreign key:
- customer_id references customers(customer_id)

Source:
- order_id comes from InvoiceNo
- customer_id comes from CustomerID
- order_date comes from InvoiceDate
- country comes from Country

Derived field:
- order_status

Business logic:
If the original invoice number starts with 'C', the order is classified as
'Cancelled'. Otherwise, the order is classified as 'Completed'.

Possible values for order_status:
- Completed
- Cancelled

Notes:
An order can contain multiple products, so one order can have many rows in
the order_items table.

===============================================================================
5. order_items
===============================================================================

Purpose:
Stores product-level details for each order.

Grain:
One row per product line in an order.

Columns:

- order_item_id
- order_id
- product_id
- quantity
- unit_price
- line_total

Primary key:
- order_item_id

Foreign keys:
- order_id references orders(order_id)
- product_id references products(product_id)

Source:
- order_id comes from InvoiceNo
- product_id comes from StockCode
- quantity comes from Quantity
- unit_price comes from UnitPrice

Derived field:
- line_total = quantity * unit_price

Business logic:
This table is the main fact table for revenue and product-level analysis.

It will be used to calculate:
- revenue;
- number of units sold;
- average selling price;
- product performance;
- customer spending;
- product profitability.

===============================================================================
6. payments
===============================================================================

Purpose:
Stores payment-level information.

Grain:
One row per order.

Columns:

- payment_id
- order_id
- payment_method
- payment_status
- payment_date

Primary key:
- payment_id

Foreign key:
- order_id references orders(order_id)

Source:
This table does not exist in the original dataset.

The payment information will be simulated for educational and analytical purposes.

Possible payment_method values:
- Credit Card
- PayPal
- Bank Transfer
- Voucher

Possible payment_status values:
- Paid
- Failed
- Refunded
- Pending

Business logic:
Completed orders will usually have a payment status of 'Paid'.
Cancelled orders may have a payment status of 'Refunded' or 'Failed'.

This table will support:
- payment method analysis;
- failed payment analysis;
- refunded order analysis;
- dashboard KPIs.

===============================================================================
7. shipments
===============================================================================

Purpose:
Stores shipment-level information.

Grain:
One row per order.

Columns:

- shipment_id
- order_id
- shipping_date
- delivery_date
- delivery_status
- shipping_cost

Primary key:
- shipment_id

Foreign key:
- order_id references orders(order_id)

Source:
This table does not exist in the original dataset.

The shipment information will be simulated for educational and analytical purposes.

Possible delivery_status values:
- Delivered
- Delayed
- Returned
- Cancelled

Business logic:
Completed orders will usually have a delivery status of 'Delivered' or 'Delayed'.
Cancelled orders will usually have a delivery status of 'Cancelled'.

This table will support:
- delivery performance analysis;
- late delivery analysis;
- return analysis;
- shipping cost analysis;
- operational dashboard KPIs.

===============================================================================
ENTITY RELATIONSHIP OVERVIEW
===============================================================================

customers 1 --- many orders

orders 1 --- many order_items

products 1 --- many order_items

orders 1 --- 1 payments

orders 1 --- 1 shipments

Conceptual model:

customers
    |
    | customer_id
    |
orders
    |
    | order_id
    |
order_items
    |
    | product_id
    |
products

orders
    |
    | order_id
    |
payments

orders
    |
    | order_id
    |
shipments

===============================================================================
ANALYTICAL USE OF EACH TABLE
===============================================================================

raw_online_retail:
- data quality checks;
- source data validation;
- transformation audit.

customers:
- customer count;
- customer country distribution;
- customer segmentation;
- customer lifetime value.

products:
- product catalog;
- product performance;
- price analysis;
- profitability analysis.

orders:
- order volume;
- monthly order trends;
- customer purchasing activity;
- retention analysis;
- cancelled order analysis.

order_items:
- revenue analysis;
- product-level sales;
- category/product performance;
- customer spending;
- RFM analysis;
- feature engineering.

payments:
- payment performance;
- failed payments;
- refunded transactions;
- payment method preferences.

shipments:
- delivery performance;
- shipping costs;
- delayed orders;
- operational performance.

===============================================================================
PLANNED NEXT STEP
===============================================================================

The next file, 02_create_tables.sql, will create the PostgreSQL tables based on
this schema design.

The implementation will include:

- CREATE TABLE statements;
- primary keys;
- foreign keys;
- appropriate data types;
- constraints;
- basic derived fields where needed.

===============================================================================
*/
