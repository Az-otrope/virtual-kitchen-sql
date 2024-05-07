-- **************************************************
-- Impacted customers are from: KY - concord, georgetown, ashland; CA - oakland, pleasant hill; TX - arlington, brownsville
-- Find each customer's #-food preference and their distance to Chicago and Gary stores
-- **************************************************
-- Rework
-- **************************************************

-- 1. customer id and name
with customers as (
    select
        customer_id,
        first_name || ' ' || last_name as customer_name
    from vk_data.customers.customer_data
),

-- 2. customer and food preference counts
customer_food_pref_cnt as (
    select 
        c.customer_id,
        c.customer_name,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey cs
    inner join customers c
        on cs.customer_id = c.customer_id
    where is_active = true
    group by 1, 2
),

-- 3. US cities geography
city_geo as (
    select
        lower(trim(city_name)) as city,
        lower(trim(state_abbr)) as state,
        geo_location
    from vk_data.resources.us_cities
),

-- 4. impacted customers from CA, TX, KY 
impacted_customers as (
    select
        customer_id,
        lower(trim(customer_city)) as impacted_city,
        lower(trim(customer_state)) as impacted_state
    from vk_data.customers.customer_address as ca
    where (impacted_state = 'ca' and impacted_city in ('oakland', 'pleasant hill'))
        or (impacted_state = 'ky' and impacted_city in ('concord', 'georgetown', 'ashland'))
        or (impacted_state = 'tx' and impacted_city in ('arlington', 'brownsville'))
),

impacted_customers_geo as (
    select
        ic.*,
        cg.geo_location
    from impacted_customers as ic
    left join city_geo as cg
        on ic.impacted_city = cg.city
        and ic.impacted_state = cg.state
),

-- 5. Chicago and Gary stores geo
chicago_geo as (
    select 
        geo_location
    from vk_data.resources.us_cities 
    where city_name = 'CHICAGO' and state_abbr = 'IL'
),

gary_geo as (
    select 
        geo_location
    from vk_data.resources.us_cities 
    where city_name = 'GARY' and state_abbr = 'IN'
)
    
select 
    cf.customer_name,
    initcap(icg.impacted_city) as customer_city,
    upper(icg.impacted_state) as customer_state,
    cf.food_pref_count,
    (st_distance(icg.geo_location, chicago.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(icg.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles
from customer_food_pref_cnt as cf
inner join impacted_customers_geo as icg
    on cf.customer_id = icg.customer_id
cross join chicago_geo as chicago
cross join gary_geo as gary