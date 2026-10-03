-- E: If Danny wants to expand his range of pizzas,
-- how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen
-- if a new 'Supreme' pizza with all the toppings was added
-- to the Pizza Runner menu.

-- Impact on data design:
-- Adding a new pizza does not require changing the existing table structure.
-- We only need to insert a new record into pizza_names
-- and add its toppings to pizza_recipes.

-- Add the new Supreme pizza to the pizza_names table
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

-- Add all available toppings to the Supreme pizza recipe
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');