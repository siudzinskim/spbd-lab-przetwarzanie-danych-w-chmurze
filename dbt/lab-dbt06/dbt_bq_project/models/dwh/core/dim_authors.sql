-- models/dwh/core/dim_authors.sql
{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        author as author_name,
        author_rating
    FROM {{ ref('stg_books') }}
)

SELECT
    ABS(FARM_FINGERPRINT(author_name)) as author_id,
    author_name,
    author_rating
FROM base
