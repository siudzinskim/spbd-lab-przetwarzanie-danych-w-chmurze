SELECT
    book_id,
    title,
    author,
    category
FROM {{ ref('stg_books') }}
