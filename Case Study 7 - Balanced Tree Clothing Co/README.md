# Balanced Tree SQL & Power BI Case Study Analysis

## Overview

This project analyzes sales, transactions, and product performance for Balanced Tree Clothing Co. using SQL and Power BI.

The goal is to analyze overall sales performance, transaction behavior, product performance, and develop a structured reporting analysis for the business.

## Case Study Reference

Original case study:
https://8weeksqlchallenge.com/case-study-7/

## Tools

* MySQL
* Power BI

## Skills Practiced

### SQL

* SQL Joins
* Aggregations
* GROUP BY
* CASE Statements
* Common Table Expressions (CTEs)
* Window Functions
* Date and Time Functions
* Percentile Analysis
* Sales Analysis
* Transaction Analysis
* Product Analysis
* Reporting Analysis
* Recursive CTEs

### Power BI

* Data Modeling
* Power Query
* DAX
* Data Visualization
* Interactive Dashboard Design

## Dataset

The dataset contains information about Balanced Tree Clothing Co.'s products and sales transactions.

The analysis uses data related to:

* Products
* Product categories
* Product segments
* Product styles
* Prices
* Quantities
* Discounts
* Transactions
* Membership status
* Transaction dates

## SQL Files

The SQL analysis is organized into the following files:

1. `data.sql` - Creates and populates the database with the case study dataset
2. `01-High_Level_Sales_Analysis.sql` - Analyzes overall sales performance
3. `02-Transaction_Analysis.sql` - Analyzes transaction-level metrics and customer membership behavior
4. `03-Product_Analysis.sql` - Analyzes product, segment, and category performance
5. `03-Reporting_Challenge.sql` - Combines the analysis into a structured reporting script
6. `05-Bonus_Challenge.sql` - Answers the bonus challenge using the product hierarchy and pricing datasets

## Power BI Dashboard

A Power BI dashboard was created to visualize the analysis and present key business insights interactively.

Power BI file:

`case study 7.pbix`

## Business Questions

The analysis covers questions related to:

### A. High Level Sales Analysis

* Total quantity sold
* Total revenue before discounts
* Total discount amount

### B. Transaction Analysis

* Number of unique transactions
* Average number of unique products per transaction
* Revenue percentiles per transaction
* Average discount per transaction
* Member vs non-member transaction split
* Average revenue for member and non-member transactions

### C. Product Analysis

* Top products by revenue
* Sales performance by segment
* Top-selling products by segment
* Sales performance by category
* Top-selling products by category
* Revenue distribution across products, segments, and categories
* Product transaction penetration
* Common product combinations

### D. Reporting Challenge

The reporting challenge combines the previous analyses into a structured monthly report that can be used to generate business metrics for different reporting periods.

### E. Bonus Challenge

The bonus challenge uses the product hierarchy and product pricing datasets to recreate the product details table using SQL.

## Key SQL Concepts

This case study provided practice with:

* Exploring sales and transaction data
* Joining product and sales tables
* Aggregating sales metrics
* Calculating revenue and discounts
* Analyzing transaction-level data
* Using percentile functions
* Applying conditional logic with `CASE`
* Using window functions
* Performing product and category analysis
* Creating monthly reporting queries
* Using recursive CTEs
* Working with hierarchical product data

## Key Power BI Concepts

This case study also provided practice with:

* Data modeling
* Power Query transformations
* DAX
* Data visualization
* Interactive dashboards
* Presenting business insights through dashboards
