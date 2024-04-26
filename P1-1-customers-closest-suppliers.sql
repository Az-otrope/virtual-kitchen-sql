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
WITH geo AS (
    SELECT
    lower(trim(city_name)) AS city,
    lower(trim(state_abbr)) AS state,
    geo_location
    --COUNT(*) -- each pair of city-state can have >1 geo_location
FROM vk_data.resources.us_cities
QUALIFY ROW_NUMBER() OVER(PARTITION BY city, state ORDER BY city) = 1
),

-- 2. join the suppliers with geo_location 
supplier_geo AS (
    SELECT
        si.supplier_id,
        si.supplier_name,
        geo.city,
        geo.state,
        geo.geo_location AS supp_loc
    FROM vk_data.suppliers.supplier_info si
    LEFT JOIN geo
        ON lower(trim(si.supplier_city)) = geo.city AND lower(trim(si.supplier_state)) = geo.state
),

-- 3. join the customers with geo_location 
-- 3a. using INNER JOIN to filter eligible customers (those with shipping address)
customer_geo AS (
    SELECT
        ca.customer_id,
        ca.customer_city,
        ca.customer_state,
        cd.first_name,
        cd.last_name,
        cd.email,
        geo.city,
        geo.state,
        geo.geo_location AS cust_loc
    FROM vk_data.customers.customer_address ca
    INNER JOIN geo
        ON lower(trim(ca.customer_city)) = geo.city AND lower(trim(ca.customer_state)) = geo.state
    INNER JOIN vk_data.customers.customer_data cd
        ON ca.customer_id = cd.customer_id
)

-- 4. Find customers and their closest suppliers, one row per customer
-- 4a. Have to compare each customer to 10 stores to calculate the distances -> cross join
-- 4b. For each customer, assign row_number() ordering by distance asc, then choose the closest one
SELECT
    cg.customer_id,
    cg.first_name,
    cg.last_name,
    cg.email,
    sg.supplier_id,
    sg.supplier_name,
    ST_DISTANCE(cg.cust_loc, sg.supp_loc) / 1609 AS distance_to_store_miles
    -- cg.cust_loc,
    -- sg.supp_loc
FROM customer_geo cg 
CROSS JOIN supplier_geo sg
QUALIFY ROW_NUMBER() OVER(PARTITION BY cg.customer_id ORDER BY distance_to_store_miles ASC) = 1
ORDER BY cg.last_name, cg.first_name