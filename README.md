Online Learning Enrollment Analytics Platform | Databricks

Project Overview

This project implements an end-to-end data engineering pipeline for an online learning platform using Databricks SQL and Lakeflow Spark Declarative Pipelines.

The solution follows the Medallion Architecture (Bronze, Silver, and Gold) to ingest raw enrollment data, perform data cleaning and validation, generate business-level aggregations, and present analytical insights through Databricks AI/BI dashboards.

The primary objective is to convert inconsistent enrollment records into reliable, structured, and analytics-ready datasets.

Business Objectives

Build an automated data processing workflow using Databricks.

Implement Bronze, Silver, and Gold data layers.

Identify and handle duplicate records, missing values, and invalid data.

Standardize learner information and enrollment attributes.

Create business-ready summary tables using SQL.

Monitor data quality and validate record reconciliation.

Develop interactive dashboards for business analysis.

Technology Stack

Technology

Purpose

Databricks

Data engineering platform

SQL

Data transformation and aggregation

Lakeflow Spark Declarative Pipelines

Pipeline development and execution

Unity Catalog

Data organization and file management

Medallion Architecture

Layered data processing

Databricks AI/BI

Interactive dashboards

Architecture – Medallion Architecture

1. Bronze Layer – Data Ingestion

Loaded the raw CSV dataset through Unity Catalog Volumes.

Created a Bronze streaming table using read_files().

Preserved source data without applying cleaning transformations.

Captured source file name and ingestion timestamp.

Output: bronze_course_enrollments

2. Silver Layer – Data Cleaning & Validation

Performed data cleaning and transformation using Databricks SQL.

Key operations:

Removed duplicate enrollment records using DISTINCT.

Standardized text fields using TRIM() and INITCAP().

Cleaned email addresses using LOWER() and TRIM().

Handled missing categories, cities, and payment values using COALESCE().

Applied data quality expectations to reject invalid progress percentages and negative prices.

Created learner status using CASE WHEN.

Separated valid and rejected records.

Outputs:

silver_enrollments_clean

silver_enrollments_rejected

3. Gold Layer – Business Aggregation

Created business-ready summary tables using SQL aggregations and GROUP BY.

Gold Table

Business Purpose

gold_monthly_enrollments

Monthly enrollment and revenue trends

gold_category_summary

Category-wise performance

gold_course_summary

Course-level revenue and completion analysis

gold_channel_summary

Enrollment channel performance

gold_data_quality

Data quality metrics and reconciliation

Dashboard Development

Developed a three-page interactive dashboard using Databricks AI/BI.

Page 1 – Overview

Total enrollments

Revenue

Completions

Total unique learners

Monthly revenue trends

Revenue by category

Learner status distribution

Page 2 – Courses & Channels

Top 10 courses by revenue

Completion rate by category

Enrollments by channel

Revenue by channel

Page 3 – Data Quality

Bronze, clean, rejected, and duplicate records

Learner counts before and after email cleaning

Data quality issues by type

Reconciliation status

Data Quality & Processing Results

Metric

Result

Bronze Records

1,283

Clean Records

1,241

Rejected Records

19

Duplicate Records

23

Reconciliation

Passed

Reconciliation Formula:

Bronze Records = Clean Records + Rejected Records + Duplicate Records

1,283 = 1,241 + 19 + 23

Key Learnings

Implementing Medallion Architecture in Databricks.

Developing SQL-based ETL pipelines.

Working with Lakeflow Spark Declarative Pipelines.

Applying data quality expectations.

Handling duplicate and inconsistent records.

Building analytical summary tables.

Creating interactive Databricks AI/BI dashboards.

Validating data through reconciliation.

Project Outcome

Successfully implemented an end-to-end data engineering workflow that transforms raw online learning enrollment data into clean, validated, and business-ready datasets.

The project demonstrates how Databricks and Medallion Architecture can support structured data processing, data quality management, and business intelligence reporting.
