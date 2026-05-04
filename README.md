# E-commerce Customer Intelligence with SQL and Python

## Project Overview

This project is an end-to-end data analytics and customer intelligence project based on an e-commerce business scenario.

The goal is to analyze customer behavior, revenue trends, product profitability, retention patterns, and customer repurchase probability using SQL, Python, and dashboarding tools.

The project simulates a real-world analytics workflow, starting from database design and data quality checks, then moving into advanced SQL analysis, customer segmentation, cohort retention analysis, feature engineering for machine learning, predictive modeling, and executive dashboard creation.

The final objective is to generate actionable business insights that can help an e-commerce company improve revenue, customer retention, profitability, and marketing strategy.

---

## Dataset

This project uses the **Online Retail dataset** from the UCI Machine Learning Repository as the main transactional data source.

The dataset contains transactional records from a UK-based online retail company between December 2010 and December 2011. It includes invoice-level product purchases, customer identifiers, product descriptions, quantities, unit prices, invoice dates, and customer countries.

The original dataset includes the following fields:

- InvoiceNo
- StockCode
- Description
- Quantity
- InvoiceDate
- UnitPrice
- CustomerID
- Country

To support a more complete analytics workflow, the original dataset will be transformed into a relational database model and enriched with additional simulated business tables such as payments, shipments, and product costs.

These additional fields will allow the project to include profitability analysis, operational analysis, dashboard KPIs, customer segmentation, and predictive modeling.

Dataset source: UCI Machine Learning Repository — Online Retail Dataset.

---

## Business Problem

An e-commerce company wants to better understand its customers, sales performance, and product profitability.

Although the company collects transactional data, it lacks a structured analytical framework to answer key business questions such as:

- Which customers generate the most revenue?
- Which product categories are the most profitable?
- Are customers returning after their first purchase?
- Which customer segments are at risk of churn?
- Can we predict whether a customer is likely to purchase again?
- How can the business improve retention and profitability?

This project addresses these questions by building a complete analytics workflow using SQL and Python.

---

## Project Objectives

The main objectives of this project are:

1. Design a relational database for an e-commerce business.
2. Perform data quality checks and data cleaning using SQL.
3. Analyze revenue trends, customer behavior, and product performance.
4. Calculate key business metrics such as revenue, average order value, repeat purchase rate, customer lifetime value, and profit margin.
5. Perform cohort retention analysis to understand customer retention over time.
6. Build RFM customer segmentation to identify high-value, loyal, at-risk, and lost customers.
7. Create SQL-based features for a customer repurchase prediction model.
8. Build a machine learning model in Python to predict whether a customer is likely to purchase again.
9. Develop an executive dashboard to communicate insights clearly.
10. Provide business recommendations based on the analysis.

---

## Tools and Technologies

- **SQL Database:** PostgreSQL
- **SQL Client:** DBeaver or pgAdmin
- **Programming Language:** Python
- **Python Libraries:** pandas, numpy, scikit-learn, matplotlib
- **Notebook Environment:** Jupyter Notebook
- **Dashboard Tool:** Power BI, Tableau, or Streamlit
- **Version Control:** GitHub
- **Documentation:** Markdown

---

## Repository Structure

```text
ecommerce-customer-intelligence-sql-python/
│
├── README.md
│
├── data/
│   ├── raw/
│   │   └── ecommerce_raw.csv
│   ├── processed/
│   │   └── ecommerce_cleaned.csv
│   ├── data_dictionary.md
│   └── source.md
│
├── database/
│   ├── 01_schema_design.sql
│   ├── 02_create_tables.sql
│   ├── 03_import_data.sql
│   ├── 04_constraints_and_indexes.sql
│   └── erd_diagram.png
│
├── sql/
│   ├── 01_data_quality_checks.sql
│   ├── 02_data_cleaning.sql
│   ├── 03_revenue_analysis.sql
│   ├── 04_customer_behavior_analysis.sql
│   ├── 05_product_profitability_analysis.sql
│   ├── 06_cohort_retention_analysis.sql
│   ├── 07_rfm_segmentation.sql
│   ├── 08_customer_lifetime_value.sql
│   ├── 09_customer_model_features.sql
│   ├── 10_dashboard_views.sql
│   └── 11_query_optimization.sql
│
├── notebooks/
│   ├── 01_sql_data_extraction.ipynb
│   ├── 02_exploratory_data_analysis.ipynb
│   ├── 03_customer_repurchase_prediction.ipynb
│   └── 04_model_evaluation.ipynb
│
├── dashboard/
│   ├── dashboard_screenshots/
│   └── dashboard_description.md
│
├── reports/
│   ├── executive_summary.md
│   ├── technical_report.md
│   └── business_recommendations.md
│
└── presentation/
    └── project_presentation.pdf
```

---

## Project Progress

The project is currently in progress. The following modules have been created and documented:

### Completed SQL and Database Modules

| Module | File | Status |
|---|---|---|
| Dataset documentation | `data/source.md` | Completed |
| Data dictionary | `data/data_dictionary.md` | Completed |
| Database schema design | `database/01_schema_design.sql` | Completed |
| Table creation script | `database/02_create_tables.sql` | Completed |
| Data import workflow | `database/03_import_data.sql` | Completed |
| Raw-to-relational transformation | `database/04_constraints_and_indexes.sql` | Completed |
| Data quality checks | `sql/01_data_quality_checks.sql` | Completed |
| Data cleaning views | `sql/02_data_cleaning.sql` | Completed |
| Revenue analysis | `sql/03_revenue_analysis.sql` | Completed |
| Customer behavior analysis | `sql/04_customer_behavior_analysis.sql` | Completed |
| Product profitability analysis | `sql/05_product_profitability_analysis.sql` | Completed |
| Cohort retention analysis | `sql/06_cohort_retention_analysis.sql` | Completed |
| RFM segmentation | `sql/07_rfm_segmentation.sql` | Completed |
| Customer lifetime value analysis | `sql/08_customer_lifetime_value.sql` | Completed |
| SQL feature engineering for ML | `sql/09_customer_model_features.sql` | Completed |
| Dashboard-ready SQL views | `sql/10_dashboard_views.sql` | Completed |
| Query optimization | `sql/11_query_optimization.sql` | Completed |

### Next Planned Modules

The next project modules will focus on:

1. Preparing the dataset for local analysis.
2. Converting the original Excel file into CSV format.
3. Importing the data into PostgreSQL.
4. Running SQL scripts and validating outputs.
5. Creating the Python notebook for exploratory data analysis.
6. Building the customer repurchase prediction model.
7. Creating the executive dashboard.
8. Writing the final business recommendations.

---

## Analysis Plan

The project will be divided into the following analytical modules:

### 1. Database Design

Design a normalized relational database containing customers, orders, order items, products, payments, and shipments.

### 2. Data Quality Assessment

Identify missing values, duplicates, inconsistent dates, invalid transactions, and other data quality issues.

### 3. Revenue Analysis

Analyze total revenue, monthly revenue trends, average order value, and revenue growth over time.

### 4. Customer Behavior Analysis

Analyze customer purchasing patterns, repeat purchase behavior, top customers, and customer activity.

### 5. Product Profitability Analysis

Evaluate product and category performance using revenue, cost, profit, and margin metrics.

### 6. Cohort Retention Analysis

Measure how customer groups behave over time based on their first purchase month.

### 7. RFM Segmentation

Segment customers based on recency, frequency, and monetary value.

### 8. Customer Lifetime Value

Estimate customer value using historical purchasing behavior.

### 9. Predictive Modeling

Build a machine learning model to predict whether a customer is likely to purchase again within a defined time period.

### 10. Dashboard and Business Recommendations

Create an executive dashboard and summarize key insights into actionable business recommendations.

---

## Expected Outcomes

By the end of this project, the following deliverables will be produced:

- A relational PostgreSQL database
- SQL scripts for data cleaning and analysis
- Advanced SQL queries using CTEs and window functions
- Customer segmentation outputs
- Cohort retention analysis
- Customer lifetime value analysis
- Machine learning dataset created with SQL
- Python predictive model
- Executive dashboard
- Final business report
- GitHub repository suitable for portfolio and job applications

---

## Key Business Questions

This project aims to answer the following questions:

- What are the main drivers of revenue?
- Which products and categories are the most profitable?
- Which customers generate the highest value?
- How many customers make repeat purchases?
- How does customer retention change over time?
- Which customers are at risk of churn?
- Can customer repurchase behavior be predicted?
- What actions can the business take to improve retention and profitability?

---

## Status

Project in progress.
