-- Original query
with supplier_geography as (
    select
        supplier_id,
        supplier_name,
        suppliers.supplier_location,
        geo_location
    from (
        select
            supplier_id,
            supplier_name,
            supplier_city || ', ' || supplier_state as supplier_location,
            trim(upper(supplier_city)) as supplier_city,
            trim(upper(supplier_state)) as supplier_state
        from vk_data.suppliers.supplier_info
    ) suppliers
    join (
        select 
            city.city_id,
            trim(upper(city.city_name)) as city_name,
            trim(upper(city.state_abbr)) as state_abbr,
            city.lat,
            city.long,
            city.geo_location
        from vk_data.resources.us_cities city
        join 
            (select 
                city_name,
                state_abbr,
                min(city_id) as city_id
            from vk_data.resources.us_cities
            group by 
                city_name,
                state_abbr) ucity on city.city_id = ucity.city_id
    ) as city_details
        on suppliers.supplier_city = city_details.city_name and suppliers.supplier_state = city_details.state_abbr
)

select
    s.supplier_id,
    s.supplier_name,
    cc.location_main,
    cc.location_backup,
    round(cc.distance_measure / 1609) as travel_miles
from (select 
        supplier_main,
            min(distance_measure) as closest_distance
        from (
                select 
                    sg1.supplier_id as supplier_main,
                    sg2.supplier_id as supplier_backup,
                    sg1.supplier_location as location_main,
                    sg2.supplier_location as location_backup,
                    st_distance(sg1.geo_location, sg2.geo_location) as distance_measure
                from supplier_geography sg1
                join supplier_geography sg2
        )
        where distance_measure > 0
        group by supplier_main) as cs
join (select 
        sg1.supplier_id as supplier_main,
        sg2.supplier_id as supplier_backup,
        sg1.supplier_location as location_main,
        sg2.supplier_location as location_backup,
        st_distance(sg1.geo_location, sg2.geo_location) as distance_measure
    from supplier_geography sg1
    join supplier_geography sg2
) cc on cs.closest_distance = cc.distance_measure
    and cs.supplier_main = cc.supplier_main
join (
        select
            supplier_id,
            supplier_name,
            supplier_city || ', ' || supplier_state as supplier_location,
            trim(upper(supplier_city)) as supplier_city,
            trim(upper(supplier_state)) as supplier_state
        from vk_data.suppliers.supplier_info
    ) as s on cs.supplier_main = s.supplier_id
order by s.supplier_name


-- **************************************************
-- Find the main and backup location for each supplier. The backup location is closest to the main one
-- Outputs: supplier_id, supplier_name, location_main, location_backup, travel_miles
-- **************************************************
-- Rework
-- **************************************************

-- 1. Unique cities with ids and city-state name
with unique_cities as (
    select 
        city_name,
        state_abbr,
        min(city_id) as city_id
    from vk_data.resources.us_cities
    group by 
        city_name,
        state_abbr
),

-- 2. Cities details information
city_details as (
    select 
        city.city_id,
        trim(upper(city.city_name)) as city_name,
        trim(upper(city.state_abbr)) as state_abbr,
        city.lat,
        city.long,
        city.geo_location
    from vk_data.resources.us_cities as city
    left join unique_cities as ucity
        on city.city_id = ucity.city_id
),

-- 3. suppliers table
suppliers as (
    select 
        supplier_id,
        supplier_name,
        supplier_city || ', ' || supplier_state as supplier_location,
        trim(upper(supplier_city)) as supplier_city,
        trim(upper(supplier_state)) as supplier_state
    from vk_data.suppliers.supplier_info    
),

-- 4. suppliers' geolocation
supplier_geography as (
    select
        supplier_id,
        supplier_name,
        suppliers.supplier_location,
        geo_location
    from suppliers
    left join city_details
        on suppliers.supplier_city = city_details.city_name 
            and suppliers.supplier_state = city_details.state_abbr
),

-- 5. compare the distance for each supplier to the rest
city_to_city_distance as (
    select 
        sg1.supplier_id as supplier_main,
        sg2.supplier_id as supplier_backup,
        sg1.supplier_location as location_main,
        sg2.supplier_location as location_backup,
        st_distance(sg1.geo_location, sg2.geo_location) as distance_measure
    from supplier_geography sg1
    cross join supplier_geography sg2
),

-- 6. suppliers and the closest distance 
closest_supplier as (
    select 
        supplier_main,
        min(distance_measure) as closest_distance
    from city_to_city_distance
    where distance_measure > 0
    group by supplier_main
)

select
    s.supplier_id,
    s.supplier_name,
    cc.location_main,
    cc.location_backup,
    round(cc.distance_measure / 1609) as travel_miles
from closest_supplier cs
join city_to_city_distance cc 
    on cs.closest_distance = cc.distance_measure
    and cs.supplier_main = cc.supplier_main
join suppliers as s
    on cs.supplier_main = s.supplier_id
order by s.supplier_name
-- 4. suppliers' geolocation
supplier_geography as (
    select
        supplier_id,
        supplier_name,
        suppliers.supplier_location,
        geo_location
    from suppliers
    left join city_details
        on suppliers.supplier_city = city_details.city_name 
            and suppliers.supplier_state = city_details.state_abbr
),

-- 5. compare the distance for each supplier to the rest
city_to_city_distance as (
    select 
        sg1.supplier_id as supplier_main,
        sg2.supplier_id as supplier_backup,
        sg1.supplier_location as location_main,
        sg2.supplier_location as location_backup,
        st_distance(sg1.geo_location, sg2.geo_location) as distance_measure
    from supplier_geography sg1
    cross join supplier_geography sg2
),

-- 6. suppliers and the closest distance 
closest_supplier as (
    select 
        supplier_main,
        min(distance_measure) as closest_distance
    from city_to_city_distance
    where distance_measure > 0
    group by supplier_main
)

select
    s.supplier_id,
    s.supplier_name,
    cc.location_main,
    cc.location_backup,
    round(cc.distance_measure / 1609) as travel_miles
from closest_supplier cs
join city_to_city_distance cc 
    on cs.closest_distance = cc.distance_measure
    and cs.supplier_main = cc.supplier_main
join suppliers as s
    on cs.supplier_main = s.supplier_id
order by s.supplier_name