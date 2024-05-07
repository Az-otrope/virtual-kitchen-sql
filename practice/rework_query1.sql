select 
    first_name || ' ' || last_name as customer_name,
    customer_city,
    customer_state,
    tag_property
from vk_data.customers.customer_data cd
join vk_data.customers.customer_address ca on cd.customer_id = ca.customer_id
join vk_data.customers.customer_survey cs on cd.customer_id = cs.customer_id
join vk_data.resources.recipe_tags rt on cs.tag_id = rt.tag_id
where is_active = true and tag_property in (' served-hot', ' 30-minutes-or-less') and customer_state in ('NY', 'CA')

-- This query gives names of customers from NY and CA states, who has active preferences for recipes that are 'served-hot' or '30-minute-or-less'

-- ****************************************************************
-- Format changes to the query before peer review 
-- 1. Add "as" for table alias
-- 2. being specific about which table the columns come from
-- 3. being specific about type of join
-- 4. breakdown a long line (break on where, and, or, etc.)
-- ****************************************************************
select 
    cd.first_name || ' ' || last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    rt.tag_property
from vk_data.customers.customer_data as cd
inner join vk_data.customers.customer_address as ca 
    on cd.customer_id = ca.customer_id
inner join vk_data.customers.customer_survey as cs 
    on cd.customer_id = cs.customer_id
inner join vk_data.resources.recipe_tags as rt 
    on cs.tag_id = rt.tag_id
where cs.is_active = true 
    and rt.tag_property in (' served-hot', ' 30-minutes-or-less')
    and ca.customer_state in ('NY', 'CA')