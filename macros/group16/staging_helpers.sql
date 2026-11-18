{% macro group16_local_datetime(column, timezone, variable_name) -%}
    {# Read the loader before setting this. UTC can mean local clock text was
       loaded unchanged; America/New_York means the loader stored real instants. #}
    {% if timezone not in ['UTC', 'America/New_York'] %}
        {% if execute %}
            {{ exceptions.raise_compiler_error(
                'Confirm the raw timestamp encoding in the Cloud Function, then set '
                ~ variable_name ~ ' to UTC or America/New_York. See GROUP16_HANDOFF.md.'
            ) }}
        {% endif %}
        {# Placeholder for dbt's parse phase only; builds cannot use this default. #}
        {% set timezone = 'UTC' %}
    {% endif %}
    datetime({{ column }}, '{{ timezone }}')
{%- endmacro %}

{% macro group16_borough(column) -%}
    case upper(regexp_replace(trim({{ column }}), r'\s+', ' '))
        when 'MANHATTAN' then 'MANHATTAN'
        when 'NEW YORK' then 'MANHATTAN'
        when 'BROOKLYN' then 'BROOKLYN'
        when 'QUEENS' then 'QUEENS'
        when 'BRONX' then 'BRONX'
        when 'THE BRONX' then 'BRONX'
        when 'STATEN ISLAND' then 'STATEN ISLAND'
        else 'Unknown'
    end
{%- endmacro %}

{% macro group16_zip(column) -%}
    case
        when regexp_contains(trim({{ column }}), r'^\d{5}(-\d{4})?$')
             and substr(trim({{ column }}), 1, 5) != '00000'
            then substr(trim({{ column }}), 1, 5)
        else 'Unknown'
    end
{%- endmacro %}

{% macro group16_integer(column) -%}
    safe_cast(nullif(trim(cast({{ column }} as string)), '') as int64)
{%- endmacro %}

{% macro group16_invalid_count(column) -%}
    (
        nullif(trim(cast({{ column }} as string)), '') is not null
        and ({{ group16_integer(column) }} is null or {{ group16_integer(column) }} < 0)
    )
{%- endmacro %}
