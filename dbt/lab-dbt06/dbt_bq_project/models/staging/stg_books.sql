-- models/staging/stg_books.sql
WITH source AS (
    SELECT
        CAST(index AS INT64) as book_id,
        Publishing_Year as publishing_year,
        Book_Name as title,
        Author as author,
        language_code,
        Author_Rating as author_rating,
        Book_average_rating as book_average_rating,
        Book_ratings_count as book_ratings_count,
        genre as category,
        gross_sales,
        publisher_revenue,
        sale_price as price,
        sales_rank,
        Publisher_ as publisher,
        units_sold
    FROM {{ source('gcs_raw', 'ext_books') }}
),

dummy_record AS (
    SELECT
        -1 as book_id,
        NULL as publishing_year,
        'Nieznana Książka (Błąd danych)' as title,
        'System' as author,
        'PL' as language_code,
        '0' as author_rating,
        0.0 as book_average_rating,
        0 as book_ratings_count,
        'Unknown' as category,
        0.0 as gross_sales,
        0.0 as publisher_revenue,
        0.0 as price,
        99999 as sales_rank,
        'System' as publisher,
        0 as units_sold
)

SELECT * FROM source
UNION ALL
SELECT * FROM dummy_record
