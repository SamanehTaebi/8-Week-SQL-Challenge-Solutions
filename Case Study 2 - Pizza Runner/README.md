# Pizza Runner SQL Case Study Analysis

## Overview

This project analyzes pizza orders, customer data, runner activity, and delivery performance for Pizza Runner using SQL.

The goal is to answer business questions related to:

* Pizza orders and customer preferences
* Runner and delivery performance
* Pizza preparation and delivery times
* Ingredient changes and pizza modifications
* Pricing and ratings

## Case Study Reference

Original case study:
https://8weeksqlchallenge.com/case-study-2/

## Tools

* MySQL

## Skills Practiced

* SQL Joins
* Aggregations
* GROUP BY
* CASE Statements
* Common Table Expressions (CTEs)
* Date and Time Functions
* String Functions
* Data Cleaning
* Data Transformation
* Window Functions
* Business Data Analysis

## Dataset

The dataset contains information about customers, pizza orders, runners, pizza recipes, and pizza toppings.

The database contains the following tables:

* `customer_orders` - customer pizza orders and order details
* `runner_orders` - runner information and delivery details
* `pizza_names` - pizza names
* `pizza_recipes` - ingredients used for each pizza
* `pizza_toppings` - pizza topping information

## SQL Files

The analysis is organized into separate SQL files covering the complete case study:

1. `01_create_database_and_tables.sql` - Creates the database and required tables
2. `02_insert_raw_data.sql` - Inserts the original raw dataset
3. `03_data_cleaning.sql` - Cleans and prepares the raw data for analysis
4. `04_pizza_metrics.sql` - Answers questions related to pizza orders and customer metrics
5. `05_Runner_and_Customer_Experience.sql` - Analyzes runner performance and customer experience
6. `06_Ingredient_Optimisation.sql` - Analyzes pizza ingredients, exclusions, and extras
7. `07_Pricing_and_Ratings.sql` - Analyzes pricing, ratings, and related business metrics
8. `08_Bonus_Questions.sql` - Answers additional bonus questions from the case study

## Business Questions

The analysis covers questions across the following areas:

### A. Pizza Metrics

* Pizza order volume
* Customer order patterns
* Pizza preferences
* Order and delivery metrics

### B. Runner and Customer Experience

* Runner performance
* Delivery times
* Distance traveled
* Delivery success rates
* Customer experience

### C. Ingredient Optimisation

* Pizza toppings
* Ingredient exclusions
* Extra ingredients
* Ingredient combinations

### D. Pricing and Ratings

* Pizza pricing
* Order revenue
* Runner ratings
* Performance metrics

### E. Bonus Questions

Additional business questions based on the Pizza Runner dataset.

## Key SQL Concepts

This case study provided practice with:

* Data cleaning and handling inconsistent values
* Working with dates and timestamps
* Calculating delivery and preparation times
* Joining multiple tables
* Aggregating customer and order data
* Working with comma-separated ingredient lists
* Using CTEs for complex analysis
* Conditional calculations with `CASE`
* Window functions
* Business-focused data analysis
