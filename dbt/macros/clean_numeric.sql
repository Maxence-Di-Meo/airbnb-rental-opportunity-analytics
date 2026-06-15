{% macro clean_numeric(column_name) -%}
nullif(
    replace(
        regexp_replace(coalesce(cast({{ column_name }} as text), ''), '[^0-9,.-]', '', 'g'),
        ',',
        '.'
    ),
    ''
)::numeric
{%- endmacro %}

