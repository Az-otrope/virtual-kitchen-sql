-- ****************************************************************
-- Question: determine which customers are eligible to order from Virtual Kitchen, 
--           and which distributor will handle the orders that they place. 

-- Outputs: Eligible customers (city & state present in the database) and the closest supplier by distance to each 

-- Return cols: Customer ID, Customer first name, Customer last name, Customer email, 
--              Supplier ID, Supplier name, Shipping distance in kilometers or miles (you choose)
-- ****************************************************************


-- 1. To calculate the shipping distance, I need geo_location -> resources.us_cities table
-- 1a. remove replicates of city and state, remove text formatting (upper/lower-case, spacing)
-- 1b. choose any one geo_location for a pair of city-state
with geo as (
    select
        lower(trim(city_name))as city,
        lower(trim(state_abbr))as state,
        geo_location
        --count(*) -- each pair of city-state can have >1 geo_location
    from vk_data.resources.us_cities
    qualify row_number() over(partition by city, state order by city) = 1
),

-- 2. join the suppliers with geo_location 
supplier_geo as (
    select
        si.supplier_id,
        si.supplier_name,
        geo.city,
        geo.state,
        geo.geo_location as supp_loc
    from vk_data.suppliers.supplier_info si
    left join geo
        on lower(trim(si.supplier_city)) = geo.city and lower(trim(si.supplier_state)) = geo.state
),

-- 3. join the customers with geo_location 
-- 3a. using inner join to filter eligible customers (those with shipping address)
customer_geo as (
    select
        ca.customer_id,
        ca.customer_city,
        ca.customer_state,
        cd.first_name,
        cd.last_name,
        cd.email,
        geo.city,
        geo.state,
        geo.geo_location as cust_loc
    from vk_data.customers.customer_address ca
    inner join geo
        on lower(trim(ca.customer_city)) = geo.city and lower(trim(ca.customer_state)) = geo.state
    inner join vk_data.customers.customer_data cd
        on ca.customer_id = cd.customer_id
)

-- 4. Find customers and their closest suppliers, one row per customer
-- 4a. Have to compare each customer to 10 stores to calculate the distances -> cross join
-- 4b. For each customer, assign row_number() ordering by distance asc, then choose the closest one
select
    cg.customer_id,
    cg.first_name,
    cg.last_name,
    cg.email,
    sg.supplier_id,
    sg.supplier_name,
    st_distance(cg.cust_loc, sg.supp_loc) / 1609 as distance_to_store_miles
    -- cg.cust_loc,
    -- sg.supp_loc
from customer_geo cg 
cross join supplier_geo sg
qualify row_number() over(partition by cg.customer_id order by distance_to_store_miles asc) = 1
order by cg.last_name, cg.first_name