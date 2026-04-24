-- models/dwh/core/dim_books.sql
{{ config(materialized='table') }}

SELECT
    book_id,
    title,
    author,
    ABS(FARM_FINGERPRINT(author)) as author_id,
    publisher,
    ABS(FARM_FINGERPRINT(publisher)) as publisher_id,
    category
FROM {{ ref('stg_books') }}
