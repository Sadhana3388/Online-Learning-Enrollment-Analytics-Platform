# **Online Learning Enrollment Analytics Platform using Databricks**

## **📌 Project Overview**

This project focuses on building an end-to-end data engineering platform for analyzing online learning enrollment data using **Databricks SQL and Lakeflow Spark Declarative Pipelines**.

The solution follows the **Medallion Architecture (Bronze, Silver, and Gold)** to ingest raw enrollment data, perform data cleaning and validation, generate business-ready summary tables, and deliver analytical insights through Databricks AI/BI dashboards.

The main objective is to transform inconsistent raw enrollment records into reliable, structured, and analytics-ready datasets.

## **🎯 Business Objectives**

- Build an end-to-end data engineering pipeline using Databricks.
- Implement Bronze, Silver, and Gold layers.
- Identify and handle duplicate records, missing values, and inconsistent data.
- Standardize learner information and enrollment attributes.
- Create business-ready summary tables using SQL.
- Implement data quality checks and reconciliation.
- Develop interactive dashboards for business analysis.

## **🛠️ Technologies Used**

| Technology | Purpose |
|---|---|
| Databricks | Data Engineering Platform |
| SQL | Data Cleaning, Transformation and Aggregation |
| Lakeflow Spark Declarative Pipelines | Pipeline Development |
| Unity Catalog | Data Organization and File Management |
| Medallion Architecture | Layered Data Processing |
| Databricks AI/BI | Interactive Dashboard Development |

## **🏗️ Data Architecture – Medallion Architecture**

The project follows a three-layer architecture to process data systematically.

### **🥉 1. Bronze Layer – Data Ingestion**

- Loaded the raw CSV dataset into Databricks using Unity Catalog Volumes.
- Created a Bronze streaming table using `read_files()`.
- Preserved the original source data.
- Captured source file information and ingestion timestamps.

**Output Table:** `bronze_course_enrollments`

### **🥈 2. Silver Layer – Data Cleaning & Transformation**

Performed data cleaning and validation using Databricks SQL.

**Key Operations:**
- Removed duplicate enrollment records using `DISTINCT`.
- Standardized text fields using `TRIM()` and `INITCAP()`.
- Cleaned email addresses using `LOWER()` and `TRIM()`.
- Handled missing categories, cities, and payment values using `COALESCE()`.
- Applied data quality expectations to identify invalid progress percentages and negative prices.
- Created learner status using `CASE WHEN`.
- Separated valid and rejected records.

**Output Tables:**
- `silver_enrollments_clean`
- `silver_enrollments_rejected`

### **🥇 3. Gold Layer – Business Aggregation**

Created business-ready summary tables using SQL aggregations and `GROUP BY`.

| Gold Table | Business Purpose |
|---|---|
| `gold_monthly_enrollments` | Monthly enrollment and revenue trends |
| `gold_category_summary` | Category-wise performance |
| `gold_course_summary` | Course-level performance |
| `gold_channel_summary` | Enrollment channel analysis |
| `gold_data_quality` | Data quality metrics and reconciliation |

## **📊 Dashboard Development – Databricks AI/BI**

Developed a three-page interactive dashboard using Gold-layer tables.

### **📍 Page 1 – Overview**

- KPI cards for enrollments, revenue, completions, and unique learners.
- Monthly revenue trends.
- Revenue distribution by category.
- Learner status analysis.

### **📍 Page 2 – Courses & Channels**

- Top 10 courses by revenue.
- Completion rate by category.
- Enrollments by channel.
- Revenue by channel.

### **📍 Page 3 – Data Quality**

- Bronze, clean, rejected, and duplicate record counts.
- Learner counts before and after email cleaning.
- Data quality issues by type.
- Reconciliation status.

## **📈 Data Quality & Processing Results**

The pipeline processed the raw enrollment dataset and generated the following results:

| Metric | Result |
|---|---:|
| Bronze Records | 1,283 |
| Clean Records | 1,241 |
| Rejected Records | 19 |
| Duplicate Records | 23 |
| Reconciliation Status | Passed |

**Reconciliation Formula:**

`Bronze Records = Clean Records + Rejected Records + Duplicate Records`

`1,283 = 1,241 + 19 + 23`

This confirms that all source records were accounted for across the clean, rejected, and duplicate categories.

## **💡 Key Learnings**

- Understanding and implementing Medallion Architecture.
- Developing SQL-based ETL pipelines.
- Working with Lakeflow Spark Declarative Pipelines.
- Managing data using Unity Catalog.
- Implementing data quality expectations.
- Handling duplicate and inconsistent records.
- Creating business-level aggregation tables.
- Developing interactive Databricks AI/BI dashboards.
- Validating data using reconciliation techniques.

