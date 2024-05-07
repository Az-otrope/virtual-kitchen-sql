-- ****************************************************************
-- Find recipes with preferences: < 3 ingredients, served-hot, 30-mintues or less
-- Use recipes by chef WalterL only, customers from NY and CA
-- Output: customer names, address info, recipe name, chef name
-- ****************************************************************

-- Original query
with three_ingredient_recipes as (
    select 
        r.recipe_id,
        r.chef_id,
        flat_r.value as tag_value,
        r.recipe_name
    from vk_data.chefs.recipe as r
    , table(flatten(tag_list)) as flat_r
    where ingredient_count < 3 
)

select 
    cd.first_name || ' ' || cd.last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    rt.tag_property,
    r.recipe_name,
    cp.username
from vk_data.customers.customer_data as cd
inner join vk_data.customers.customer_address as ca 
    on cd.customer_id = ca.customer_id
inner join vk_data.customers.customer_survey as cs 
    on cd.customer_id = cs.customer_id
inner join vk_data.resources.recipe_tags as rt 
    on cs.tag_id = rt.tag_id
inner join three_ingredient_recipes as r
    on r.tag_value ilike '%' || trim(rt.tag_property) || '%'
inner join vk_data.chefs.chef_profile as cp
    on r.chef_id = cp.chef_id
where cs.is_active = true 
    and rt.tag_property in (' served-hot', ' 30-minutes-or-less') 
    and ca.customer_state in ('NY', 'CA')
    and trim(cp.username) = 'WALTERL'

-- ****************************************************************
-- Rework the query
-- ****************************************************************
with three_ingredient_recipes as (
    select 
        r.recipe_id,
        r.chef_id,
        flat_r.value as tag_value,
        r.recipe_name
    from vk_data.chefs.recipe as r,
    table(flatten(tag_list)) as flat_r
    where ingredient_count < 3 
),

chef_walterl as (
    select
        chef_id,
        username
    from vk_data.chefs.chef_profile
    where trim(username) = 'WALTERL'
),

ca_ny_customers as (
    select
        cd.customer_id,
        cd.first_name || ' ' || cd.last_name as customer_name,
        ca.customer_city,
        ca.customer_state
    from vk_data.customers.customer_data as cd
    inner join vk_data.customers.customer_address as ca
        on cd.customer_id = ca.customer_id
    where ca.customer_state in ('CA', 'NY')
)

select 
    cnc.customer_name,
    cnc.customer_city,
    cnc.customer_state,
    rt.tag_property,
    r.recipe_name,
    cwl.username
from ca_ny_customers as cnc
inner join vk_data.customers.customer_survey as cs 
    on cnc.customer_id = cs.customer_id
inner join vk_data.resources.recipe_tags as rt 
    on cs.tag_id = rt.tag_id
inner join three_ingredient_recipes as r
    on r.tag_value ilike '%' || trim(rt.tag_property) || '%'
inner join chef_walterl as cwl
    on r.chef_id = cwl.chef_id
where cs.is_active = True
    and rt.tag_property in (' served-hot', ' 30-minutes-or-less')