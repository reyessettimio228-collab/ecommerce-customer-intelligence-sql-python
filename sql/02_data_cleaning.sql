/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 02_data_cleaning.sql
Purpose: Clean and prepare the Online Retail dataset for analysis
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script documents the cleaning logic used to prepare the dataset for business
analysis.

The raw dataset contains several records that require special handling, including:

- missing customer IDs;
- cancelled invoices;
- negative quantities;
- zero or negative unit prices;
- missing product descriptions;
- duplicate rows.

The goal is not to delete raw data, but to create clean analytical views that can
be used consistently across the project.

===============================================================================
*/

-- =============================================================================
-- 1. Create a clean transactional view
-- =============================================================================
-- This view keeps only valid completed sales transactions.
--
-- Cleaning rules:
-- - customer_id must not be null;
-- - invoice_no must not be null;
-- - stock_code must not be null;
-- - description must not be null;
-- - quantity must be greater than 0;
-- - unit_price must be greater than 0;
-- - cancelled invoices are excluded;
-- - line_total is calculated as quantity * unit_price.

DROP VIEW IF EXISTS vw_clean_transactions;

CREATE VIEW vw_clean_transactions AS
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    ROUND(quantity * unit_price, 2) AS line_total
FROM raw_online_retail
WHERE customer_id IS NOT NULL
  AND invoice_no IS NOT NULL
  AND stock_code IS NOT NULL
  AND description IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';

-- =============================================================================
-- 2. Create a clean orders view
-- =============================================================================
-- This view aggregates clean transactions at invoice/order level.

DROP VIEW IF EXISTS vw_clean_orders;

CREATE VIEW vw_clean_orders AS
SELECT
    invoice_no AS order_id,
    customer_id,
    MIN(invoice_date) AS order_date,
    country,
    COUNT(DISTINCT stock_code) AS unique_products,
    SUM(quantity) AS total_items,
    ROUND(SUM(quantity * unit_price), 2) AS order_revenue
FROM vw_clean_transactions
GROUP BY
    invoice_no,
    customer_id,
    country;

-- =============================================================================
-- 3. Create a clean customers view
-- =============================================================================
-- This view summarizes customer-level behavior based on valid completed orders.

DROP VIEW IF EXISTS vw_clean_customers;

CREATE VIEW vw_clean_customers AS
SELECT
    customer_id,
    country,
    COUNT(DISTINCT invoice_no) AS total_orders,
    MIN(invoice_date) AS first_order_date,
    MAX(invoice_date) AS last_order_date,
    SUM(quantity) AS total_items_purchased,
    ROUND(SUM(line_total), 2) AS total_spent,
    ROUND(AVG(line_total), 2) AS avg_line_value
FROM vw_clean_transactions
GROUP BY
    customer_id,
    country;

-- =============================================================================
-- 4. Create a clean products view
-- =============================================================================
-- This view summarizes product-level performance based on valid completed sales.

DROP VIEW IF EXISTS vw_clean_products;

CREATE VIEW vw_clean_products AS
SELECT
    stock_code AS product_id,
    description AS product_name,
    COUNT(DISTINCT invoice_no) AS number_of_orders,
    COUNT(DISTINCT customer_id) AS number_of_customers,
    SUM(quantity) AS units_sold,
    ROUND(AVG(unit_price), 2) AS avg_unit_price,
    ROUND(SUM(line_total), 2) AS product_revenue
FROM vw_clean_transactions
GROUP BY
    stock_code,
    description;

-- =============================================================================
-- 5. Create a cancelled transactions view
-- =============================================================================
-- Cancelled invoices are kept in a separate view for cancellation and returns
-- analysis.

DROP VIEW IF EXISTS vw_cancelled_transactions;

CREATE VIEW vw_cancelled_transactions AS
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    ROUND(quantity * unit_price, 2) AS cancellation_value
FROM raw_online_retail
WHERE invoice_no LIKE 'C%';

-- =============================================================================
-- 6. Create a data quality issue summary view
-- =============================================================================
-- This view provides a compact overview of the main data quality issues.

DROP VIEW IF EXISTS vw_data_quality_summary;

CREATE VIEW vw_data_quality_summary AS
SELECT
    COUNT(*) AS total_raw_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id_rows,
    COUNT(*) FILTER (WHERE invoice_no IS NULL) AS missing_invoice_no_rows,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS missing_stock_code_rows,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_description_rows,
    COUNT(*) FILTER (WHERE quantity <= 0) AS non_positive_quantity_rows,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS non_positive_unit_price_rows,
    COUNT(*) FILTER (WHERE invoice_no LIKE 'C%') AS cancelled_invoice_rows
FROM raw_online_retail;

-- =============================================================================
-- 7. Validate clean transactions
-- =============================================================================

-- Count clean transaction rows
SELECT
    COUNT(*) AS clean_transaction_rows
FROM vw_clean_transactions;

-- Check clean transaction date range
SELECT
    MIN(invoice_date) AS first_clean_invoice_date,
    MAX(invoice_date) AS last_clean_invoice_date
FROM vw_clean_transactions;

-- Check clean revenue
SELECT
    ROUND(SUM(line_total), 2) AS clean_total_revenue
FROM vw_clean_transactions;

-- Check clean orders
SELECT
    COUNT(*) AS clean_orders
FROM vw_clean_orders;

-- Check clean customers
SELECT
    COUNT(*) AS clean_customers
FROM vw_clean_customers;

-- Check clean products
SELECT
    COUNT(*) AS clean_products
FROM vw_clean_products;

-- =============================================================================
-- 8. Compare raw rows vs clean rows
-- =============================================================================

SELECT
    raw_counts.total_raw_rows,
    clean_counts.clean_transaction_rows,
    raw_counts.total_raw_rows - clean_counts.clean_transaction_rows AS excluded_rows,
    ROUND(
        100.0 * clean_counts.clean_transaction_rows / raw_counts.total_raw_rows,
        2
    ) AS clean_rows_percentage
FROM
    (
        SELECT COUNT(*) AS total_raw_rows
        FROM raw_online_retail
    ) raw_counts
CROSS JOIN
    (
        SELECT COUNT(*) AS clean_transaction_rows
        FROM vw_clean_transactions
    ) clean_counts;

-- =============================================================================
-- 9. Document excluded rows by reason
-- =============================================================================

SELECT
    'Missing Customer ID' AS issue_type,
    COUNT(*) AS affected_rows
FROM raw_online_retail
WHERE customer_id IS NULL

UNION ALL

SELECT
    'Cancelled Invoice' AS issue_type,
    COUNT(*) AS affected_rows
FROM raw_online_retail
WHERE invoice_no LIKE 'C%'

UNION ALL

SELECT
    'Non-positive Quantity' AS issue_type,
    COUNT(*) AS affected_rows
FROM raw_online_retail
WHERE quantity <= 0

UNION ALL

SELECT
    'Non-positive Unit Price' AS issue_type,
    COUNT(*) AS affected_rows
FROM raw_online_retail
WHERE unit_price <= 0

UNION ALL

SELECT
    'Missing Description' AS issue_type,
    COUNT(*) AS affected_rows
FROM raw_online_retail
WHERE description IS NULL
ORDER BY affected_rows DESC;

/*
===============================================================================
End of file: 02_data_cleaning.sql
===============================================================================
*/
