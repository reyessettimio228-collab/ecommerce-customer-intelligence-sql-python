/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 03_import_data.sql
Purpose: Import the Online Retail dataset into PostgreSQL
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================

IMPORT WORKFLOW
-------------------------------------------------------------------------------

The original dataset is provided as an Excel file:

    Online Retail.xlsx

PostgreSQL does not directly import Excel files using the COPY command.

Therefore, the recommended workflow is:

    1. Open Online Retail.xlsx
    2. Save/export the file as CSV
    3. Name the CSV file: online_retail.csv
    4. Import the CSV file into the raw_online_retail table
    5. Use SQL transformation scripts to populate the relational tables

Recommended local folder structure:

    data/
    ├── raw/
    │   └── online_retail.csv
    └── processed/

IMPORTANT:
The full raw dataset may not be stored directly in this GitHub repository.
For reproducibility, users should download the dataset from the official source
and place the CSV file inside data/raw/.

===============================================================================
EXPECTED CSV COLUMNS
===============================================================================

The CSV file should contain the following columns:

    InvoiceNo
    StockCode
    Description
    Quantity
    InvoiceDate
    UnitPrice
    CustomerID
    Country

These columns will be imported into the raw_online_retail table using the
following mapping:

    InvoiceNo    -> invoice_no
    StockCode    -> stock_code
    Description  -> description
    Quantity     -> quantity
    InvoiceDate  -> invoice_date
    UnitPrice    -> unit_price
    CustomerID   -> customer_id
    Country      -> country

===============================================================================
OPTION 1: IMPORT USING pgAdmin
===============================================================================

If using pgAdmin:

1. Right-click the table:

       raw_online_retail

2. Select:

       Import/Export Data

3. Choose:

       Import

4. Select the CSV file:

       data/raw/online_retail.csv

5. Format:

       CSV

6. Header:

       Yes

7. Delimiter:

       ,

8. Quote:

       "

9. Match the CSV columns with the raw_online_retail table columns.

10. Run the import.

===============================================================================
OPTION 2: IMPORT USING DBeaver
===============================================================================

If using DBeaver:

1. Right-click the table:

       raw_online_retail

2. Select:

       Import Data

3. Choose:

       CSV

4. Select the file:

       data/raw/online_retail.csv

5. Confirm the column mapping.

6. Run the import.

===============================================================================
OPTION 3: IMPORT USING SQL COPY
===============================================================================

The COPY command can be used when the CSV file is accessible to the PostgreSQL
server.

Example:

COPY raw_online_retail (
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country
)
FROM 'C:/path/to/data/raw/online_retail.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ',',
    QUOTE '"',
    ENCODING 'UTF8'
);

NOTE:
The file path must be changed based on the local machine.

On Windows, use forward slashes or escaped backslashes.

Example:

    C:/Users/YourName/Desktop/ecommerce-customer-intelligence-sql-python/data/raw/online_retail.csv

===============================================================================
OPTION 4: IMPORT USING psql \copy
===============================================================================

If using psql, the \copy command is often easier because it reads the file from
the local machine rather than the PostgreSQL server.

Example:

\copy raw_online_retail (
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country
)
FROM 'C:/Users/YourName/Desktop/ecommerce-customer-intelligence-sql-python/data/raw/online_retail.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ',',
    QUOTE '"',
    ENCODING 'UTF8'
);

===============================================================================
POST-IMPORT VALIDATION CHECKS
===============================================================================

After importing the data, run the following checks.

-------------------------------------------------------------------------------
1. Count total rows
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows
FROM raw_online_retail;

Expected result:
The original dataset contains more than 500,000 rows.

-------------------------------------------------------------------------------
2. Preview imported data
-------------------------------------------------------------------------------

SELECT
    *
FROM raw_online_retail
LIMIT 10;

-------------------------------------------------------------------------------
3. Check date range
-------------------------------------------------------------------------------

SELECT
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date
FROM raw_online_retail;

-------------------------------------------------------------------------------
4. Count unique invoices
-------------------------------------------------------------------------------

SELECT
    COUNT(DISTINCT invoice_no) AS unique_invoices
FROM raw_online_retail;

-------------------------------------------------------------------------------
5. Count unique customers
-------------------------------------------------------------------------------

SELECT
    COUNT(DISTINCT customer_id) AS unique_customers
FROM raw_online_retail
WHERE customer_id IS NOT NULL;

-------------------------------------------------------------------------------
6. Count unique products
-------------------------------------------------------------------------------

SELECT
    COUNT(DISTINCT stock_code) AS unique_products
FROM raw_online_retail;

-------------------------------------------------------------------------------
7. Check missing customer IDs
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS rows_with_missing_customer_id
FROM raw_online_retail
WHERE customer_id IS NULL;

-------------------------------------------------------------------------------
8. Check cancelled invoices
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS cancelled_invoice_rows
FROM raw_online_retail
WHERE invoice_no LIKE 'C%';

-------------------------------------------------------------------------------
9. Check negative quantities
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS rows_with_negative_quantity
FROM raw_online_retail
WHERE quantity < 0;

-------------------------------------------------------------------------------
10. Check zero or negative unit prices
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS rows_with_invalid_unit_price
FROM raw_online_retail
WHERE unit_price <= 0;

===============================================================================
EXPECTED NEXT STEP
===============================================================================

After the raw dataset is imported into raw_online_retail, the next step is to
transform the raw data into the relational tables:

    customers
    products
    orders
    order_items
    payments
    shipments

This transformation will be implemented in:

    database/04_constraints_and_indexes.sql

and later refined in:

    sql/02_data_cleaning.sql

===============================================================================
End of file: 03_import_data.sql
===============================================================================
*/
