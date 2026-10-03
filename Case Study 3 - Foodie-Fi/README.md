# Foodie-Fi SQL Case Study Analysis

## Overview

This project analyzes customer subscription data for Foodie-Fi, a subscription-based streaming service, using SQL.

The goal is to understand customer subscription journeys, plan changes, churn behavior, and payment patterns.

## Case Study Reference

Original case study:
https://8weeksqlchallenge.com/case-study-3/

## Tools

* MySQL

## Skills Practiced

* SQL Joins
* Aggregations
* GROUP BY
* CASE Statements
* Common Table Expressions (CTEs)
* Window Functions
* Date and Time Functions
* Customer Journey Analysis
* Subscription Analysis
* Data Transformation

## Dataset

The dataset contains information about Foodie-Fi customers, subscription plans, and subscription events.

The database contains the following tables:

* `plans` - information about the available subscription plans and their prices
* `subscriptions` - customer subscription events, including plan changes and subscription dates

## SQL Files

The analysis is organized into separate SQL files covering the complete case study:

1. `01_creating_data_table.sql` - Creates the database tables and prepares the dataset
2. `02_Customer_Journey.sql` - Analyzes customer subscription journeys and plan changes
3. `03_Data_Analysis_Questions.sql` - Answers the main data analysis questions from the case study
4. `04_Challenge_Payment_Question.sql` - Answers the challenge payment question

## Business Questions

The analysis covers questions related to:

### A. Customer Journey

* Customer subscription journeys
* Plan changes over time
* Customer subscription patterns
* Churn and upgrade behavior

### B. Data Analysis

* Customer distribution across subscription plans
* Subscription trends
* Plan changes and customer behavior
* Churn analysis

### C. Challenge Payment Question

* Payment-related analysis
* Subscription pricing
* Customer payment behavior

## Key SQL Concepts

This case study provided practice with:

* Joining customer and subscription data
* Working with dates
* Analyzing customer journeys
* Identifying plan changes
* Calculating customer and subscription metrics
* Using CTEs for complex analysis
* Conditional logic with `CASE`
* Window functions
* Business-focused subscription analysis
