-- ****************************************************************
-- We want to launch an email marketing campaign to let these eligibles customers know that they can order from our website. 
-- If the customer completed a survey about their food interests, then we also want to include up to three of their choices in a personalized email message.

-- Outputs: eligible customers with up to first 3 food preferences and 1 recipe for food preference #1
--          sort food preferences alphabetically; order the results by customer email.

-- Return cols: Customer ID, Customer email, Customer first name
--              Food preference #1, Food preference #2, Food preference #3, one suggested recipe_name 
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
with geo as (
    select distinct
        lower(trim(city_name)) as city,
        lower(trim(state_abbr)) as state,
        geo_location
    from vk_data.resources.us_cities
),

-- 1b. join the customers with geo_location 
customer_geo as (
    select
        ca.customer_id,
        cd.email,
        cd.first_name
    from vk_data.customers.customer_address ca
    inner join geo
        on lower(trim(ca.customer_city)) = geo.city and lower(trim(ca.customer_state)) = geo.state
    inner join vk_data.customers.customer_data cd
        on ca.customer_id = cd.customer_id
),

-- 2. get the customers preferences (i.e. tag_property), join via tag_id
-- 2a. assign row_number for later use to get 3 refs 
customer_pref_tags as (
    select
        cg.*,
        rt.tag_property,
        row_number() over (partition by cs.customer_id
                            order by rt.tag_property) as tag_row_id
    from customer_geo cg
    inner join vk_data.customers.customer_survey cs
        on cg.customer_id = cs.customer_id
    inner join vk_data.resources.recipe_tags rt
        on cs.tag_id = rt.tag_id
    where cs.is_active = TRUE
    order by cg.email
    ),
    
-- 2b. pivot to get up to 3 food prefs for each customer
customers_3prefs as (
    select *
    from customer_pref_tags
    pivot(min(tag_property) for tag_row_id in (1,2,3))
        as p(customer_id, email, first_name, food_pref_1, food_pref_2, food_pref_3)
),

-- 3. flatten the tag_list in the 'recipe' table to produce a list of recipe tag_properties
recipe_property as (
    select
        recipe_id,
        recipe_name,
        trim(replace(value, '"', '')) as tag_property_values
    from vk_data.chefs.recipe,
        table(flatten(tag_list))    
)

-- 4. match the food_pref_1 to the recipe tag_property to get the recipe_name
-- note: the food_pref_# values have trailing spaces. Need to trim() to match tag_property_values
-- if not trim(), suggested_recipe returns NULL
select
    c3p.*,
    recipe_name as suggested_recipe
from customers_3prefs c3p 
left join recipe_property rp
    on trim(c3p.food_pref_1) = rp.tag_property_values
qualify row_number() over(partition by customer_id order by recipe_id) = 1
order by c3p.email