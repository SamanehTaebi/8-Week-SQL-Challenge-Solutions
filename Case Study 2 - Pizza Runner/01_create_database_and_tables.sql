CREATE DATABASE pizza_runner;
USE pizza_runner;


-- Runners registered with Pizza Runner

CREATE TABLE runners (
    runner_id INTEGER PRIMARY KEY,
    registration_date DATE
);


-- Pizza menu

CREATE TABLE pizza_names (
    pizza_id INTEGER PRIMARY KEY,
    pizza_name VARCHAR(50)
);


-- Available pizza toppings

CREATE TABLE pizza_toppings (
    topping_id INTEGER PRIMARY KEY,
    topping_name VARCHAR(50)
);


-- Each pizza has a list of topping IDs stored as a comma-separated string.
-- This follows the original case study structure and will be cleaned later.

CREATE TABLE pizza_recipes (
    pizza_id INTEGER PRIMARY KEY,
    toppings TEXT,
    FOREIGN KEY (pizza_id) REFERENCES pizza_names(pizza_id)
);


-- Each row represents one pizza within a customer order.
-- order_id is not unique because an order can contain multiple pizzas.

CREATE TABLE customer_orders (
    order_id INTEGER,
    customer_id INTEGER,
    pizza_id INTEGER,
    exclusions VARCHAR(4),
    extras VARCHAR(4),
    order_date TIMESTAMP,
    FOREIGN KEY (pizza_id) REFERENCES pizza_names(pizza_id)
);


-- Runner assignments and delivery information.
-- Some fields are stored as VARCHAR because the raw data contains
-- inconsistent formats and units. These will be cleaned later.

CREATE TABLE runner_orders (
    order_id INTEGER PRIMARY KEY,
    runner_id INTEGER,
    pickup_time VARCHAR(19),
    distance VARCHAR(7),
    duration VARCHAR(10),
    cancellation VARCHAR(23),
    FOREIGN KEY (runner_id) REFERENCES runners(runner_id)
);