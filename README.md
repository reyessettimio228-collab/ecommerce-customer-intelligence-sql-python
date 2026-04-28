# E-commerce Customer Intelligence with SQL and Python

## Project Overview

This project is an end-to-end data analytics and customer intelligence project based on an e-commerce business scenario.

The goal is to analyze customer behavior, revenue trends, product profitability, retention patterns, and customer repurchase probability using SQL, Python, and dashboarding tools.

The project simulates a real-world analytics workflow, starting from database design and data quality checks, then moving into advanced SQL analysis, customer segmentation, cohort retention analysis, feature engineering for machine learning, predictive modeling, and executive dashboard creation.

The final objective is to generate actionable business insights that can help an e-commerce company improve revenue, customer retention, profitability, and marketing strategy.

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
│   └── data_dictionary.md
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
