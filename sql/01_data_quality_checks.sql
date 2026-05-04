/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 01_data_quality_checks.sql
Purpose: Perform data quality checks on the raw Online Retail dataset
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

This script investigates the quality of the raw transactional dataset before
performing business analysis.

The checks include:

- row counts;
- missing values;
- duplicate rows;
- cancelled invoices;
- negative quantities;
- invalid unit prices;
- inconsistent product descriptions;
- multiple prices for the same product;
- customers associated with multiple countries;
- date range validation;
- revenue sanity checks.

===============================================================================
*/

-- =============================================================================
-- 1. Basic dataset overview
-- =============================================================================

-- Total number of rows in the raw dataset
SELECT
    COUNT(*) AS total_rows
FROM raw_online_retail;

-- Preview first rows
SELECT
    *
FROM raw_online_retail
LIMIT 20;

-- Count unique invoices, products, customers, and countries
SELECT
    COUNT(DISTINCT invoice_no) AS unique_invoices,
    COUNT(DISTINCT stock_code) AS unique_products,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT country) AS unique_countries
FROM raw_online_retail;

-- Date range of the dataset
SELECT
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date
FROM raw_online_retail;

-- =============================================================================
-- 2. Missing values check
-- =============================================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE invoice_no IS NULL) AS missing_invoice_no,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS missing_stock_code,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_description,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
    COUNT(*) FILTER (WHERE invoice_date IS NULL) AS missing_invoice_date,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_price,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE country IS NULL) AS missing_country
FROM raw_online_retail;

-- Percentage of rows with missing customer_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS rows_missing_customer_id,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE customer_id IS NULL) / COUNT(*),
        2
    ) AS missing_customer_id_percentage
FROM raw_online_retail;

-- =============================================================================
-- 3. Duplicate rows check
-- =============================================================================

-- Exact duplicate rows
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    COUNT(*) AS duplicate_count
FROM raw_online_retail
GROUP BY
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Count number of duplicate row groups
WITH duplicate_rows AS (
    SELECT
        invoice_no,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country,
        COUNT(*) AS duplicate_count
    FROM raw_online_retail
    GROUP BY
        invoice_no,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count - 1) AS extra_duplicate_rows
FROM duplicate_rows;

-- =============================================================================
-- 4. Cancelled invoices check
-- =============================================================================

-- Invoice numbers starting with C are treated as cancellations
SELECT
    COUNT(*) AS cancelled_invoice_rows
FROM raw_online_retail
WHERE invoice_no LIKE 'C%';

-- Cancelled invoices by country
SELECT
    country,
    COUNT(*) AS cancelled_invoice_rows
FROM raw_online_retail
WHERE invoice_no LIKE 'C%'
GROUP BY country
ORDER BY cancelled_invoice_rows DESC;

-- Check whether cancelled invoices usually have negative quantity
SELECT
    CASE
        WHEN invoice_no LIKE 'C%' THEN 'Cancelled invoice'
        ELSE 'Non-cancelled invoice'
    END AS invoice_type,
    COUNT(*) AS rows_count,
    COUNT(*) FILTER (WHERE quantity < 0) AS rows_with_negative_quantity,
    COUNT(*) FILTER (WHERE quantity > 0) AS rows_with_positive_quantity
FROM raw_online_retail
GROUP BY invoice_type;

-- =============================================================================
-- 5. Quantity checks
-- =============================================================================

-- Quantity distribution summary
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    AVG(quantity) AS avg_quantity
FROM raw_online_retail;

-- Count negative, zero, and positive quantities
SELECT
    COUNT(*) FILTER (WHERE quantity < 0) AS negative_quantity_rows,
    COUNT(*) FILTER (WHERE quantity = 0) AS zero_quantity_rows,
    COUNT(*) FILTER (WHERE quantity > 0) AS positive_quantity_rows
FROM raw_online_retail;

-- Top 20 highest quantities
SELECT
    *
FROM raw_online_retail
ORDER BY quantity DESC
LIMIT 20;

-- Top 20 lowest quantities
SELECT
    *
FROM raw_online_retail
ORDER BY quantity ASC
LIMIT 20;

-- =============================================================================
-- 6. Unit price checks
-- =============================================================================

-- Unit price distribution summary
SELECT
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price,
    AVG(unit_price) AS avg_unit_price
FROM raw_online_retail;

-- Count zero, negative, and positive unit prices
SELECT
    COUNT(*) FILTER (WHERE unit_price < 0) AS negative_unit_price_rows,
    COUNT(*) FILTER (WHERE unit_price = 0) AS zero_unit_price_rows,
    COUNT(*) FILTER (WHERE unit_price > 0) AS positive_unit_price_rows
FROM raw_online_retail;

-- Rows with invalid unit prices
SELECT
    *
FROM raw_online_retail
WHERE unit_price <= 0
ORDER BY unit_price ASC
LIMIT 100;

-- Top 20 most expensive product lines
SELECT
    *
FROM raw_online_retail
ORDER BY unit_price DESC
LIMIT 20;

-- =============================================================================
-- 7. Product consistency checks
-- =============================================================================

-- Same stock_code with multiple descriptions
SELECT
    stock_code,
    COUNT(DISTINCT description) AS different_descriptions
FROM raw_online_retail
WHERE stock_code IS NOT NULL
  AND description IS NOT NULL
GROUP BY stock_code
HAVING COUNT(DISTINCT description) > 1
ORDER BY different_descriptions DESC;

-- Same stock_code with multiple unit prices
SELECT
    stock_code,
    COUNT(DISTINCT unit_price) AS different_unit_prices,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price
FROM raw_online_retail
WHERE stock_code IS NOT NULL
  AND unit_price > 0
GROUP BY stock_code
HAVING COUNT(DISTINCT unit_price) > 1
ORDER BY different_unit_prices DESC;

-- Product codes with missing descriptions
SELECT
    stock_code,
    COUNT(*) AS rows_missing_description
FROM raw_online_retail
WHERE description IS NULL
GROUP BY stock_code
ORDER BY rows_missing_description DESC;

-- =============================================================================
-- 8. Customer consistency checks
-- =============================================================================

-- Customers associated with more than one country
SELECT
    customer_id,
    COUNT(DISTINCT country) AS number_of_countries
FROM raw_online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(DISTINCT country) > 1
ORDER BY number_of_countries DESC;

-- Top countries by number of customers
SELECT
    country,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM raw_online_retail
WHERE customer_id IS NOT NULL
GROUP BY country
ORDER BY unique_customers DESC;

-- Top countries by number of transaction rows
SELECT
    country,
    COUNT(*) AS transaction_rows
FROM raw_online_retail
GROUP BY country
ORDER BY transaction_rows DESC;

-- =============================================================================
-- 9. Revenue sanity checks
-- =============================================================================

-- Raw revenue calculation including all rows
SELECT
    ROUND(SUM(quantity * unit_price), 2) AS raw_total_revenue
FROM raw_online_retail;

-- Revenue from completed-looking transactions only
SELECT
    ROUND(SUM(quantity * unit_price), 2) AS positive_quantity_revenue
FROM raw_online_retail
WHERE quantity > 0
  AND unit_price > 0
  AND invoice_no NOT LIKE 'C%';

-- Revenue by invoice type
SELECT
    CASE
        WHEN invoice_no LIKE 'C%' THEN 'Cancelled invoice'
        ELSE 'Non-cancelled invoice'
    END AS invoice_type,
    ROUND(SUM(quantity * unit_price), 2) AS total_value,
    COUNT(*) AS rows_count
FROM raw_online_retail
GROUP BY invoice_type;

-- Top 20 invoice lines by revenue
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    ROUND(quantity * unit_price, 2) AS line_total,
    customer_id,
    country,
    invoice_date
FROM raw_online_retail
WHERE quantity > 0
  AND unit_price > 0
ORDER BY line_total DESC
LIMIT 20;

-- =============================================================================
-- 10. Order-level checks
-- =============================================================================

-- Number of product lines per invoice
SELECT
    invoice_no,
    COUNT(*) AS product_lines,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS invoice_total
FROM raw_online_retail
WHERE invoice_no IS NOT NULL
GROUP BY invoice_no
ORDER BY product_lines DESC
LIMIT 20;

-- Invoices linked to multiple customers
SELECT
    invoice_no,
    COUNT(DISTINCT customer_id) AS number_of_customers
FROM raw_online_retail
WHERE customer_id IS NOT NULL
GROUP BY invoice_no
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY number_of_customers DESC;

-- Invoices linked to multiple countries
SELECT
    invoice_no,
    COUNT(DISTINCT country) AS number_of_countries
FROM raw_online_retail
GROUP BY invoice_no
HAVING COUNT(DISTINCT country) > 1
ORDER BY number_of_countries DESC;

-- =============================================================================
-- 11. Summary of key data quality issues
-- =============================================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id_rows,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_description_rows,
    COUNT(*) FILTER (WHERE invoice_no LIKE 'C%') AS cancelled_invoice_rows,
    COUNT(*) FILTER (WHERE quantity < 0) AS negative_quantity_rows,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS invalid_unit_price_rows
FROM raw_online_retail;

/*
===============================================================================
End of file: 01_data_quality_checks.sql
===============================================================================
*/
