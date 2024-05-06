-- 25 of our customers did not get their parsley
-- We have one store in Chicago, IL and one store in Gary, IN both ready to help out with this request.
-- The bottom of the original query was to identify the impacted customers -> into a cte

with customers as (
    select
        customer_id,
        first_name || ' ' || last_name as customer_name
    from vk_data.customers.customer_data
),

food_pref_cnt_per_cust as (
    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by customer_id
),

cities as (
    select
        lower(trim(city_name)) as city,
        lower(trim(state_abbr)) as state,
        geo_location
    from vk_data.resources.us_cities
),

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
),

impacted_customers as (
    select
        customer_id,
        lower(trim(customer_city)) as impacted_city,
        lower(trim(customer_state)) as impacted_state
    from vk_data.customers.customer_address
    where 
        (impacted_state = 'ky' and 
            (impacted_city ilike '%concord%' or 
            impacted_city ilike '%georgetown%' or 
            impacted_city ilike '%ashland%')) or
        (impacted_state = 'ca' and 
            (impacted_city ilike '%oakland%' or 
            impacted_city ilike '%pleasant hill%')) or
        (impacted_state = 'tx' and 
            (impacted_city ilike '%arlington%' or 
            impacted_city ilike '%brownsville%'))
)

select
    customers.customer_name,
    initcap(impacted_customers.impacted_city) as customer_city,
    upper(impacted_customers.impacted_state) as customer_state,
    food_pref_cnt_per_cust.food_pref_count,
    (st_distance(cities.geo_location, chicago_geo.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(cities.geo_location, gary_geo.geo_location) / 1609)::int as gary_distance_miles,
from impacted_customers 
inner join customers
    on impacted_customers.customer_id = customers.customer_id
left join cities
    on impacted_customers.impacted_state = cities.state
    and impacted_customers.impacted_city = cities.city
inner join food_pref_cnt_per_cust
    on customers.customer_id = food_pref_cnt_per_cust.customer_id
cross join chicago_geo
cross join gary_geo
;