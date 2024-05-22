-- We want to create a DAILY report to track:
    -- Total unique sessions
    -- The average length of sessions in seconds
    -- The average number of searches completed before displaying a recipe 
    -- The ID of the recipe that was most viewed 
-- *********************************************************
-- Thought Process
-- *********************************************************
/* 
a user_id generates different session_id. 
Each session_id contains multiple event_timestamp (happens in each event_day) corresponding to different event_details.
For each event_day:
    1. Total unique sessions: count all unique sessions
    2. The average length of sessions in seconds: average of all sessions' length 
    3. The average number of searches completed before displaying a recipe
    4. The ID of the recipe that was most viewed: flatten the event_details column, key-value is "page":"recipe" or "event":"view_recipe"
-- *********************************************************
*/

-- flat the event_details column
-- select * from vk_data.events.website_activity order by session_id

-- select * 
-- from vk_data.events.website_activity,
-- table(flatten(parse_json(event_details))) as event_details_flat


-- alter session set use_cached_result = false;
-- 1. access the information in the event_details col to:
-- 1a. get the value for recipe_id
-- 1b. get the "event" values ("search" or "view_recipe")? -> avg(search) b4 viewing a recipe
-- Note: there are duplicates -> use distinct()
-- Note: a session_id can be repeated during a time period 
with unique_events as (
    select distinct
        event_id,
        session_id,
        event_timestamp,
        trim(parse_json(event_details):"recipe_id") as recipe_id, -- access the value of "recipe_id" key
        trim(parse_json(event_details):"event") as event_type -- access the value of "event" key 
    from vk_data.events.website_activity
    -- order by session_id
),

-- 2. count # of searches before viewing recipe
event_per_session as (
    select
        session_id,
        min(event_timestamp) as min_event_timestamp,
        max(event_timestamp) as max_event_timestamp,
        count_if(event_type = 'search') as search_cnt,
        count_if(event_type = 'view_recipe') as recipe_view_cnt
    from unique_events
    group by session_id
),

-- 3. find mostly viewed recipes for each day
-- 3a. there's a tie for the most-viewed recipe on a particular day
recipe_viewed_per_day as (
    select
        date(event_timestamp) as event_day,
        recipe_id,
        count(*) as total_views,
    from unique_events
    where recipe_id is not null
    group by 1, 2
    qualify rank() over(partition by event_day order by total_views desc) = 1
),

-- 4. list all most viewed recipe_id (if >1) for each event_day
most_viewed_recipe as (
    select 
        event_day,
        listagg(recipe_id, ', ') within group (order by total_views desc) as most_viewed_recipes
    from recipe_viewed_per_day
    group by 1
),

daily_report as (
    select 
        date(min_event_timestamp) as event_day,
        -- session_id,
        count(distinct(session_id)) as total_sessions,
        round(avg(datediff('sec', min_event_timestamp, max_event_timestamp))) as avg_session_length_sec, -- take the average of time spent in each session_id
        max(eps.search_cnt) as avg_searches_per_recipe_view,
        max(mvr.most_viewed_recipes) as most_viewed_recipes
    from event_per_session as eps
    inner join most_viewed_recipe as mvr
        on  date(eps.min_event_timestamp) = mvr.event_day
    group by 1
    order by event_day
)

select * from daily_report

-- *********************************************************
-- V0 query peformance: most expensive node 25%
-- *********************************************************