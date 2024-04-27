-- ****************************************************************
-- We want to launch an email marketing campaign to let these eligibles customers know that they can order from our website. If the customer completed a survey about their food interests, then we also want to include up to three of their choices in a personalized email message.

-- Outputs: eligible customers with up to first 3 food preferences and 1 recipe for food preference #1
--          sort food preferences alphabetically; order the results by customer email.

-- Return cols: Customer ID, Customer email, Customer first name
--              Food preference #1, Food preference #2, Food preference #3, One suggested recipe_name 
-- Return rows: 1048 rows
-- ****************************************************************

-- Thought process to develop tables relationship:
--  1. Eligible customers are from previous query, but I don't need to keep geo_location
--  2. Food preference are from 'customers_survey' table -> tag_id
--  3. tables 'customer_survey' and 'recipe_tags' are linked via tag_id -> tag_property, which carries info about recipes
--  4. tag_list col in 'recipe' table should relate to the tag_property
-- ****************************************************************

-- 1. Eligible customers have city_state present in the database
-- 1a. city_state pair with geo_location
WITH geo AS (
    SELECT DISTINCT
    lower(trim(city_name)) AS city,
    lower(trim(state_abbr)) AS state,
    geo_location
FROM vk_data.resources.us_cities
),

-- 1b. join the customers with geo_location 
customer_geo AS (
    SELECT
        ca.customer_id,
        cd.email,
        cd.first_name
    FROM vk_data.customers.customer_address ca
    INNER JOIN geo
        ON lower(trim(ca.customer_city)) = geo.city AND lower(trim(ca.customer_state)) = geo.state
    INNER JOIN vk_data.customers.customer_data cd
        ON ca.customer_id = cd.customer_id
),

-- 2. get the customers preferences (i.e. tag_property), join via tag_id
-- 2a. assign row_number for later use to get 3 refs 
customer_pref_tags AS (
    SELECT
        cg.*,
        rt.tag_property,
        ROW_NUMBER() OVER (PARTITION BY cs.customer_id
                            ORDER BY rt.tag_property) AS tag_row_id
    FROM customer_geo cg
    INNER JOIN vk_data.customers.customer_survey cs
        ON cg.customer_id = cs.customer_id
    INNER JOIN vk_data.resources.recipe_tags rt
        ON cs.tag_id = rt.tag_id
    WHERE cs.is_active = TRUE
    ORDER BY cg.email
    ),
    
-- 2b. pivot to get up to 3 food prefs for each customer
customers_3prefs AS (
    SELECT *
    FROM customer_pref_tags
    PIVOT(MIN(tag_property) FOR tag_row_id IN (1,2,3))
        AS p(customer_id, email, first_name, food_pref_1, food_pref_2, food_pref_3)
),

-- 3. flatten the tag_list in the 'recipe' table to produce a list of recipe tag_properties
recipe_property AS (
    SELECT
        recipe_id,
        recipe_name,
        trim(replace(value, '"', '')) AS tag_property_values
    FROM vk_data.chefs.recipe,
        TABLE(FLATTEN(tag_list))    
)

-- 4. match the food_pref_1 to the recipe tag_property to get the recipe_name
-- note: the food_pref_# values have trailing spaces. Need to trim() to match tag_property_values
-- if not trim(), suggested_recipe returns NULL
SELECT
    c3p.*,
    recipe_name AS suggested_recipe
FROM customers_3prefs c3p 
LEFT JOIN recipe_property rp
    ON trim(c3p.food_pref_1) = rp.tag_property_values
QUALIFY ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY recipe_id) = 1
ORDER BY c3p.email