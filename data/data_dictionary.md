# Data Dictionary

## Source Dataset: Online Retail Dataset

This project uses the **Online Retail dataset** from the UCI Machine Learning Repository.

The dataset contains transactional records from a UK-based online retail company between December 2010 and December 2011.

Each row represents a product line within an invoice. This means that a single invoice can appear multiple times if the customer purchased multiple products in the same order.

---

## Original Dataset Fields

| Column | Data Type | Description |
|---|---:|---|
| InvoiceNo | Text / Integer | Unique invoice number assigned to each transaction. If the invoice number starts with `C`, it indicates a cancellation. |
| StockCode | Text | Unique product code assigned to each distinct product. |
| Description | Text | Product name or product description. |
| Quantity | Integer | Number of product units purchased in the invoice line. Negative values may indicate returns or cancellations. |
| InvoiceDate | DateTime | Date and time when the invoice was created. |
| UnitPrice | Decimal | Unit price of the product. |
| CustomerID | Integer | Unique identifier assigned to each customer. Some records may have missing customer IDs. |
| Country | Text | Country where the customer is located. |

---

## Important Notes About the Source Data

The original dataset is provided as a single Excel table.

For this project, the dataset will be transformed into a relational database model to better simulate a real-world analytics workflow.

Important data quality aspects to check include:

- Missing customer IDs
- Duplicate records
- Negative quantities
- Zero or negative unit prices
- Cancelled invoices
- Product descriptions with missing or inconsistent values
- Multiple product prices for the same stock code
- Customers with transactions across different dates
- Orders containing multiple product lines

---

## Planned Relational Database Model

The original dataset will be transformed into the following relational tables:

---

## customers

This table will contain unique customer-level information.

| Column | Data Type | Description |
|---|---:|---|
| customer_id | Integer | Unique customer identifier from the original `CustomerID` field. |
| country | Text | Customer country. |

---

## products

This table will contain unique product-level information.

| Column | Data Type | Description |
|---|---:|---|
| product_id | Text | Unique product code from the original `StockCode` field. |
| product_name | Text | Product description from the original `Description` field. |
| unit_price | Decimal | Product unit price. |
| product_cost | Decimal | Simulated product cost used for profitability analysis. |

---

## orders

This table will contain order-level information.

| Column | Data Type | Description |
|---|---:|---|
| order_id | Text | Unique invoice number from the original `InvoiceNo` field. |
| customer_id | Integer | Customer who placed the order. |
| order_date | DateTime | Date and time when the order was created. |
| order_status | Text | Order status, such as `Completed` or `Cancelled`. |
| country | Text | Country associated with the order. |

---

## order_items

This table will contain product-level details for each order.

| Column | Data Type | Description |
|---|---:|---|
| order_item_id | Integer | Unique identifier for each order line. |
| order_id | Text | Related order identifier. |
| product_id | Text | Related product identifier. |
| quantity | Integer | Number of units purchased. |
| unit_price | Decimal | Unit price at the time of purchase. |
| line_total | Decimal | Quantity multiplied by unit price. |

---

## payments

This table will contain simulated payment information.

| Column | Data Type | Description |
|---|---:|---|
| payment_id | Integer | Unique payment identifier. |
| order_id | Text | Related order identifier. |
| payment_method | Text | Simulated payment method, such as credit card, PayPal, bank transfer, or voucher. |
| payment_status | Text | Simulated payment status, such as paid, failed, refunded, or pending. |
| payment_date | DateTime | Simulated payment date. |

---

## shipments

This table will contain simulated shipment information.

| Column | Data Type | Description |
|---|---:|---|
| shipment_id | Integer | Unique shipment identifier. |
| order_id | Text | Related order identifier. |
| shipping_date | DateTime | Simulated shipping date. |
| delivery_date | DateTime | Simulated delivery date. |
| delivery_status | Text | Simulated delivery status, such as delivered, delayed, returned, or cancelled. |
| shipping_cost | Decimal | Simulated shipping cost. |

---

## Derived Metrics

The following metrics will be created during the analysis:

| Metric | Definition |
|---|---|
| Revenue | `quantity * unit_price` |
| Average Order Value | `total revenue / number of orders` |
| Purchase Frequency | `number of orders per customer` |
| Recency | `days since last purchase` |
| Monetary Value | `total customer spending` |
| Profit | `revenue - product cost` |
| Profit Margin | `profit / revenue` |
| Repeat Purchase Rate | `customers with more than one order / total customers` |
| Customer Lifetime Value | Estimated value generated by a customer over time |
| Repurchase Target | Whether a customer purchases again within a defined time period |

---

## Planned Analytical Use Cases

This dataset will be used for:

- Revenue analysis
- Customer behavior analysis
- Product performance analysis
- Product profitability analysis
- Cohort retention analysis
- RFM customer segmentation
- Customer lifetime value estimation
- SQL feature engineering
- Customer repurchase prediction
- Executive dashboard creation
