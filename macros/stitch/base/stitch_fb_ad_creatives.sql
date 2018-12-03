{% macro stitch_fb_ad_creatives() %}

    {{ adapter_macro('facebook_ads.stitch_fb_ad_creatives') }}

{% endmacro %}


{% macro default__stitch_fb_ad_creatives() %}

with base as (

    select
    
        id,
        lower(nullif(url_tags, '')) as url_tags,
        lower(coalesce(
          nullif(object_story_spec__link_data__call_to_action__value__link, ''),
          nullif(object_story_spec__video_data__call_to_action__value__link, ''),
          nullif(object_story_spec__link_data__link, '')
        )) as url
    
    from
    {{ var('ad_creatives_table') }}

), splits as (

    select
    
        id,
        url,
        split_part(url ,'?', 1) as base_url,
        --this is a strange thing to have to do but it's because sometimes 
        --the URL exists on the story object and we wouldn't get the appropriate 
        --UTM params here otherwise
    coalesce(url_tags, split_part(url ,'?', 2)) as url_tags
    
    from base

)

select

    *,
    '/' || split_part(split_part(split_part(url, '//', 2), '/', 2), '?', 1) as url_path,
    split_part(split_part(url, '//', 2), '/', 1) as url_host,
    {{ dbt_utils.get_url_parameter('url', 'utm_source') }} as utm_source,
    {{ dbt_utils.get_url_parameter('url', 'utm_medium') }} as utm_medium,
    {{ dbt_utils.get_url_parameter('url', 'utm_campaign') }} as utm_campaign,
    {{ dbt_utils.get_url_parameter('url', 'utm_content') }} as utm_content,
    {{ dbt_utils.get_url_parameter('url', 'utm_term') }} as utm_term,
    
from splits

{% endmacro %}


{% macro snowflake__stitch_fb_ad_creatives() %}

with base as (

    select

        id,
        lower(coalesce(
          nullif(object_story_spec['link_data']['call_to_action']['value']['link']::varchar, ''),
          nullif(object_story_spec['video_data']['call_to_action']['value']['link']::varchar, ''),
          nullif(object_story_spec['link_data']['link']::varchar, '')
        )) as url

    from {{ var('ad_creatives_table') }}

),

parsed as (

    select
    
        id,
        url,
        split_part(url, '?', 1) as base_url,
        parse_url(url)['host']::varchar as url_host,
        '/' || parse_url(url)['path']::varchar as url_path,
        nullif(parse_url(url)['parameters']['utm_campaign']::varchar, '') as utm_campaign,
        nullif(parse_url(url)['parameters']['utm_source']::varchar, '') as utm_source,
        nullif(parse_url(url)['parameters']['utm_medium']::varchar, '') as utm_medium,
        nullif(parse_url(url)['parameters']['utm_content']::varchar, '') as utm_content,
        nullif(parse_url(url)['parameters']['utm_term']::varchar, '') as utm_term
        
    from base 

)

select * from parsed

{% endmacro %}