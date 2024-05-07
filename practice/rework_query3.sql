-- **************************************************
-- Find the total calories and total fat of the following recipes
-- 'birthday cookie', 'a perfect sugar cookie', 'honey oatmeal raisin cookies', 'frosted lemon cookies', 'snickerdoodles cinnamon cookies'
-- **************************************************

select
    di.recipe_name, 
    sum(di.calories) as total_calories, 
    sum(cast(replace(di.total_fat, 'g', '') as int)) as total_fat
from (
    select 
        recipe_id,
        recipe_name,
        ingredient,
        first_record,
        calories,
        total_fat
    from (
            select 
                recipe_id,
                recipe_name,
                flat_ingredients.index,
                trim(upper(replace(flat_ingredients.value, '"', ''))) as ingredient
            from vk_data.chefs.recipe,
            table(flatten(ingredients)) as flat_ingredients
        ) as r
    left join (
        select 
            trim(upper(replace(substring(ingredient_name, 1, charindex(',', ingredient_name)), ',', ''))) as ingredient_name,
            min(id) as first_record,
            max(calories) as calories,
            max(total_fat) as total_fat
        from vk_data.resources.nutrition 
        group by 1) as i on r.ingredient = i.ingredient_name
    where (recipe_name = 'birthday cookie' or recipe_name = 'a perfect sugar cookie' or
        recipe_name = 'honey oatmeal raisin cookies' or recipe_name = 'frosted lemon cookies' or
        recipe_name = 'snickerdoodles cinnamon cookies'
          )) di
join vk_data.resources.nutrition n on di.first_record = n.id
group by 1
order by 1


-- **************************************************
-- Rework
-- **************************************************

-- 1. a table with cookie recipes
with cookie_recipes as (
    select * 
    from vk_data.chefs.recipe
    where lower(recipe_name) in (
        'birthday cookie',
        'a perfect sugar cookie',
        'honey oatmeal raisin cookies', 
        'frosted lemon cookies',
        'snickerdoodles cinnamon cookies')
),

-- 2. list out all ingredients for each recipe (long format)
cookie_recipe_ingredients as (
    select 
        recipe_id,
        recipe_name,
        lower(trim(replace(flat_ingredients.value, '"', ''))) as ingredient
    from cookie_recipes,
    table(flatten(ingredients)) as flat_ingredients
),

-- 3. for each ingredient, list out their nutrition (calories, total_fat)
-- 3a. split all the ingredients by ',' and only choose the first one as main_inredient
-- 3b. remove 'g' from total_fat and cast it into int 
ingredient_info as (
    select 
        lower(split_part(ingredient_name, ',', 0)) as main_ingredient,
        max(calories) as calories,
        max(cast(replace(total_fat, 'g', '') as int)) as total_fat
    from vk_data.resources.nutrition 
    group by 1
)

select 
    cookies.recipe_name,
    sum(i_info.calories) as total_calories, 
    sum(i_info.total_fat) as total_fat
from cookie_recipe_ingredients as cookies
left join ingredient_info as i_info
    on cookies.ingredient = i_info.main_ingredient
group by cookies.recipe_name
order by cookies.recipe_name