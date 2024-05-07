-- for one specific chef, generate a list of all his recipe ingredients to make a shopping list
with recipes as (
    select
        *
    from vk_data.chefs.recipe
    where chef_id = '398e04fc-e74c-4bdf-9890-13817e74d0c2')

-- -- flatten() function produces 6 cols: SEQ, KEY, PATH, INDEX, VALUE, THIS
-- -- Need: VALUE col has the unpacked elements from THIS col. 
-- -- THIS col is the col we choose to flatten
-- select *
-- from recipes,
-- table(flatten(ingredients))


-- 1. flatten the 'ingredients' column
-- 2. work with 'value' col, replace " with space
-- 3. group by each ingredient, count how many recipes use this ingredient

select
    trim(replace(value, '"', '')) as ingredient,
    count(*) as count_of_recipes
from recipes,
table(flatten(ingredients))
group by 1
order by 1

-- *********************************************************************
-- Example 1: flatten the cell_phone array column to work with each value
-- *********************************************************************
select
    customer_id,
    flat_cell_phone.*
from vk_data.examples.customer_details,
table(flatten(cell_phone)) as flat_cell_phone

-- *********************************************************************
-- Example 2: flatten an OBJECT data type 
-- *********************************************************************

-- view a table with an OBJECT column that stores JSON
select *
from vk_data.examples.customer_employment

-- display the attributes in the OBJECT column
select  
    customer_id,
    -- flat_history.*
    flat_history.value, -- get 'value' col
    flat_history.value:employer as employer, -- key:value = "employer": value
    flat_history.value:title as job_title, -- key:value = "title": value
    flat_history.value:start_date as start_date,
    flat_history.value:end_date -- what if I don't rename the col?
from vk_data.examples.customer_employment,
table(flatten(employment_history:jobs)) as flat_history -- ":jobs" display the values in this key


-- *********************************************************************
-- Example 3: VARIANT query to flatten a group of objects within JSON
-- *********************************************************************

-- 'customer_variant' columns stores 2 data types: array and object (in form of JSON)
select * from vk_data.examples.customer_variant

-- unpack the objects
select 
    customer_id,
    flat_history.value,
    flat_history.value:employer as employer,
    flat_history.value:title as job_title
from vk_data.examples.customer_variant,
table(flatten(customer_variant:jobs)) as flat_history