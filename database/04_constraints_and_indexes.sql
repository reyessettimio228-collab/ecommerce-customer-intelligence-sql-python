/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 04_constraints_and_indexes.sql
Purpose: Transform raw data into relational tables and enrich the database
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

IMPORTANT NOTE
-------------------------------------------------------------------------------

This script assumes that:

1. The table raw_online_retail has already been created.
2. The Online Retail CSV file has already been imported into raw_online_retail.
3. The relational tables have already been created using 02_create_tables.sql.

This script populates:

- customers
- products
- orders
- order_items
- payments
- shipments

It also simulates product costs, payment information, and shipment information
for educational and analytical purposes.

===============================================================================
*/

-- =============================================================================
-- 1. Clear relational tables before inserting transformed data
-- =============================================================================
-- Tables are cleared in reverse dependency order to avoid foreign key conflicts.

TRUNCATE TABLE shipments RESTART IDENTITY CASCADE;
TRUNCATE TABLE payments RESTART IDENTITY CASCADE;
TRUNCATE TABLE order_items RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE customers CASCADE;

-- =============================================================================
-- 2. Populate customers table
-- =============================================================================
-- Only records with a valid customer_id are included.
-- If a customer appears in multiple countries, the most frequent country is used.

INSERT INTO customers (
    customer_id,
    country
)
SELECT
    customer_id,
    country
FROM (
    SELECT
        customer_id,
        country,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY COUNT(*) DESC
        ) AS country_rank
    FROM raw_online_retail
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
) ranked_customer_countries
WHERE country_rank = 1;

-- =============================================================================
-- 3. Populate products table
-- =============================================================================
-- Each StockCode becomes a product.
-- If the same StockCode has multiple descriptions or prices, the most frequent
-- description and average positive unit price are used.
--
-- product_cost is simulated as a percentage of the average unit price.
-- This allows profitability and margin analysis.

INSERT INTO products (
    product_id,
    product_name,
    standard_unit_price,
    product_cost
)
WITH product_descriptions AS (
    SELECT
        stock_code,
        description,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY COUNT(*) DESC
        ) AS description_rank
    FROM raw_online_retail
    WHERE stock_code IS NOT NULL
      AND description IS NOT NULL
    GROUP BY stock_code, description
),

product_prices AS (
    SELECT
        stock_code,
        ROUND(AVG(unit_price), 2) AS avg_unit_price
    FROM raw_online_retail
    WHERE unit_price > 0
    GROUP BY stock_code
)

SELECT
    pd.stock_code AS product_id,
    pd.description AS product_name,
    pp.avg_unit_price AS standard_unit_price,
    ROUND(pp.avg_unit_price * 0.60, 2) AS product_cost
FROM product_descriptions pd
JOIN product_prices pp
    ON pd.stock_code = pp.stock_code
WHERE pd.description_rank = 1;

-- =============================================================================
-- 4. Populate orders table
-- =============================================================================
-- Each unique InvoiceNo becomes an order.
-- Cancelled invoices are identified by invoice numbers starting with 'C'.

INSERT INTO orders (
    order_id,
    customer_id,
    order_date,
    order_status,
    country
)
SELECT
    invoice_no AS order_id,
    customer_id,
    MIN(invoice_date) AS order_date,
    CASE
        WHEN invoice_no LIKE 'C%' THEN 'Cancelled'
        ELSE 'Completed'
    END AS order_status,
    MAX(country) AS country
FROM raw_online_retail
WHERE invoice_no IS NOT NULL
  AND customer_id IS NOT NULL
GROUP BY
    invoice_no,
    customer_id;

-- =============================================================================
-- 5. Populate order_items table
-- =============================================================================
-- Each row in the raw dataset becomes one order item when it has valid references.
-- line_total is calculated as quantity * unit_price.

INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total
)
SELECT
    r.invoice_no AS order_id,
    r.stock_code AS product_id,
    r.quantity,
    r.unit_price,
    ROUND(r.quantity * r.unit_price, 2) AS line_total
FROM raw_online_retail r
JOIN orders o
    ON r.invoice_no = o.order_id
JOIN products p
    ON r.stock_code = p.product_id
WHERE r.invoice_no IS NOT NULL
  AND r.stock_code IS NOT NULL
  AND r.customer_id IS NOT NULL
  AND r.quantity <> 0
  AND r.unit_price > 0;

-- =============================================================================
-- 6. Populate payments table
-- =============================================================================
-- Payment data is simulated because the original dataset does not contain
-- payment information.
--
-- The simulation is deterministic enough for analysis, but simple enough for
-- an educational project.

INSERT INTO payments (
    order_id,
    payment_method,
    payment_status,
    payment_date
)
SELECT
    order_id,

    CASE
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 1, 8))::bit(32)::int) % 4 = 0 THEN 'Credit Card'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 1, 8))::bit(32)::int) % 4 = 1 THEN 'PayPal'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 1, 8))::bit(32)::int) % 4 = 2 THEN 'Bank Transfer'
        ELSE 'Voucher'
    END AS payment_method,

    CASE
        WHEN order_status = 'Cancelled' THEN 'Refunded'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 9, 8))::bit(32)::int) % 20 = 0 THEN 'Failed'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 9, 8))::bit(32)::int) % 20 = 1 THEN 'Pending'
        ELSE 'Paid'
    END AS payment_status,

    order_date AS payment_date

FROM orders;

-- =============================================================================
-- 7. Populate shipments table
-- =============================================================================
-- Shipment data is simulated because the original dataset does not contain
-- shipping or delivery information.
--
-- Shipping date is simulated as 1 day after the order date.
-- Delivery date is simulated as 2 to 8 days after the order date.

INSERT INTO shipments (
    order_id,
    shipping_date,
    delivery_date,
    delivery_status,
    shipping_cost
)
SELECT
    order_id,

    order_date + INTERVAL '1 day' AS shipping_date,

    order_date
        + (
            2 + ABS(('x' || SUBSTRING(MD5(order_id), 1, 8))::bit(32)::int) % 7
          ) * INTERVAL '1 day' AS delivery_date,

    CASE
        WHEN order_status = 'Cancelled' THEN 'Cancelled'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 9, 8))::bit(32)::int) % 25 = 0 THEN 'Returned'
        WHEN ABS(('x' || SUBSTRING(MD5(order_id), 9, 8))::bit(32)::int) % 10 = 0 THEN 'Delayed'
        ELSE 'Delivered'
    END AS delivery_status,

    ROUND(
        3.00 + (
            ABS(('x' || SUBSTRING(MD5(order_id), 1, 8))::bit(32)::int) % 1200
        ) / 100.0,
        2
    ) AS shipping_cost

FROM orders;

-- =============================================================================
-- 8. Validation checks after transformation
-- =============================================================================

-- Count customers
SELECT
    COUNT(*) AS total_customers
FROM customers;

-- Count products
SELECT
    COUNT(*) AS total_products
FROM products;

-- Count orders
SELECT
    COUNT(*) AS total_orders
FROM orders;

-- Count order items
SELECT
    COUNT(*) AS total_order_items
FROM order_items;

-- Count payments
SELECT
    COUNT(*) AS total_payments
FROM payments;

-- Count shipments
SELECT
    COUNT(*) AS total_shipments
FROM shipments;

-- Check order status distribution
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Check payment status distribution
SELECT
    payment_status,
    COUNT(*) AS total_payments
FROM payments
GROUP BY payment_status
ORDER BY total_payments DESC;

-- Check delivery status distribution
SELECT
    delivery_status,
    COUNT(*) AS total_shipments
FROM shipments
GROUP BY delivery_status
ORDER BY total_shipments DESC;

-- =============================================================================
-- 9. Relationship validation checks
-- =============================================================================

-- Orders without customers
SELECT
    COUNT(*) AS orders_without_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items without orders
SELECT
    COUNT(*) AS order_items_without_order
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items without products
SELECT
    COUNT(*) AS order_items_without_product
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Payments without orders
SELECT
    COUNT(*) AS payments_without_order
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Shipments without orders
SELECT
    COUNT(*) AS shipments_without_order
FROM shipments s
LEFT JOIN orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL;

/*
===============================================================================
End of file: 04_constraints_and_indexes.sql
===============================================================================
*/
