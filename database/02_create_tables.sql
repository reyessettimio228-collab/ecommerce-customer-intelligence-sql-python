/*
===============================================================================
Project: E-commerce Customer Intelligence with SQL and Python
File: 02_create_tables.sql
Purpose: Create PostgreSQL tables for the e-commerce relational database
Dataset: Online Retail Dataset - UCI Machine Learning Repository
===============================================================================
*/

-- =============================================================================
-- 0. Drop existing tables
-- =============================================================================
-- Tables are dropped in reverse dependency order to avoid foreign key conflicts.

DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS raw_online_retail;

-- =============================================================================
-- 1. Raw source table
-- =============================================================================
-- This table stores the original dataset as imported from the Excel/CSV file.
-- It preserves the original transactional structure before cleaning.

CREATE TABLE raw_online_retail (
    invoice_no      VARCHAR(20),
    stock_code      VARCHAR(50),
    description     TEXT,
    quantity        INTEGER,
    invoice_date    TIMESTAMP,
    unit_price      NUMERIC(10, 2),
    customer_id     INTEGER,
    country         VARCHAR(100)
);

-- =============================================================================
-- 2. Customers table
-- =============================================================================
-- One row per unique customer.

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    country         VARCHAR(100)
);

-- =============================================================================
-- 3. Products table
-- =============================================================================
-- One row per unique product.
-- product_cost is simulated later for profitability analysis.

CREATE TABLE products (
    product_id          VARCHAR(50) PRIMARY KEY,
    product_name        TEXT,
    standard_unit_price NUMERIC(10, 2),
    product_cost        NUMERIC(10, 2)
);

-- =============================================================================
-- 4. Orders table
-- =============================================================================
-- One row per unique invoice/order.

CREATE TABLE orders (
    order_id        VARCHAR(20) PRIMARY KEY,
    customer_id     INTEGER,
    order_date      TIMESTAMP,
    order_status    VARCHAR(20),
    country         VARCHAR(100),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_order_status
        CHECK (order_status IN ('Completed', 'Cancelled'))
);

-- =============================================================================
-- 5. Order items table
-- =============================================================================
-- One row per product line within each order.

CREATE TABLE order_items (
    order_item_id   BIGSERIAL PRIMARY KEY,
    order_id        VARCHAR(20),
    product_id      VARCHAR(50),
    quantity        INTEGER,
    unit_price      NUMERIC(10, 2),
    line_total      NUMERIC(12, 2),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- =============================================================================
-- 6. Payments table
-- =============================================================================
-- Simulated payment information.
-- One row per order.

CREATE TABLE payments (
    payment_id      BIGSERIAL PRIMARY KEY,
    order_id        VARCHAR(20) UNIQUE,
    payment_method  VARCHAR(50),
    payment_status  VARCHAR(30),
    payment_date    TIMESTAMP,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT chk_payment_method
        CHECK (payment_method IN ('Credit Card', 'PayPal', 'Bank Transfer', 'Voucher')),

    CONSTRAINT chk_payment_status
        CHECK (payment_status IN ('Paid', 'Failed', 'Refunded', 'Pending'))
);

-- =============================================================================
-- 7. Shipments table
-- =============================================================================
-- Simulated shipment information.
-- One row per order.

CREATE TABLE shipments (
    shipment_id     BIGSERIAL PRIMARY KEY,
    order_id        VARCHAR(20) UNIQUE,
    shipping_date   TIMESTAMP,
    delivery_date   TIMESTAMP,
    delivery_status VARCHAR(30),
    shipping_cost   NUMERIC(10, 2),

    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT chk_delivery_status
        CHECK (delivery_status IN ('Delivered', 'Delayed', 'Returned', 'Cancelled'))
);

-- =============================================================================
-- 8. Indexes
-- =============================================================================
-- These indexes support joins, filters, and analytical queries.

CREATE INDEX idx_raw_invoice_no
    ON raw_online_retail(invoice_no);

CREATE INDEX idx_raw_customer_id
    ON raw_online_retail(customer_id);

CREATE INDEX idx_raw_stock_code
    ON raw_online_retail(stock_code);

CREATE INDEX idx_raw_invoice_date
    ON raw_online_retail(invoice_date);

CREATE INDEX idx_orders_customer_id
    ON orders(customer_id);

CREATE INDEX idx_orders_order_date
    ON orders(order_date);

CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
    ON order_items(product_id);

CREATE INDEX idx_payments_order_id
    ON payments(order_id);

CREATE INDEX idx_shipments_order_id
    ON shipments(order_id);

/*
===============================================================================
End of file: 02_create_tables.sql
===============================================================================
*/
