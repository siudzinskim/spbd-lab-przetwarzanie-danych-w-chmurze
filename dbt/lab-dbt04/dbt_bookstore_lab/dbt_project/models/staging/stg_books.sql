-- models/staging/stg_books.sql
-- Prosty model wybierający wszystkie dane ze źródłowej tabeli books, ujednolicający nazewnictwo kolumn

{{
  config(
    materialized='table' 
  )
}}

select
    index as book_id,
    "Publishing Year" as publishing_year,
    "Book Name" as title,
    "Author" as author,
    language_code,
    "Author_Rating" as author_rating,
    "Book_average_rating" as book_average_rating,
    "Book_ratings_count" as book_ratings_count,
    genre,
    "gross sales" as gross_sales,
    "publisher revenue" as publisher_revenue,
    "sale price" as sale_price,
    "sales rank" as sales_rank,
    "Publisher " as publisher,
    "units sold" as units_sold
from {{ source('raw_data', 'books') }} -- Użycie funkcji source() do odwołania się do źródła