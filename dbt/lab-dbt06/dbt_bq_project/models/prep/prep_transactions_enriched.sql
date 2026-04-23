WITH transactions AS (
    SELECT * FROM {{ ref('stg_transactions') }}
),
customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
books AS (
    SELECT * FROM {{ ref('stg_books') }}
),

-- Krok 1: Rozpłaszczamy pozycje i łączymy z informacjami o książkach
-- Używamy COALESCE i SAFE_CAST, aby zamienić błędy na nasz klucz techniczny -1
flattened_items AS (
    SELECT
        t.transaction_id,
        STRUCT(
            COALESCE(SAFE_CAST(i.book_id AS INT64), -1) as book_id,
            b.title as book_title,
            b.author as book_author,
            b.category as book_category,
            i.unit_price,
            i.quantity
        ) as item_enriched
    FROM transactions t
    CROSS JOIN UNNEST(t.items) i
    LEFT JOIN books b ON COALESCE(SAFE_CAST(i.book_id AS INT64), -1) = b.book_id
),

-- Krok 2: Ponownie agregujemy wzbogacone pozycje do tablicy
aggregated_items AS (
    SELECT
        transaction_id,
        ARRAY_AGG(item_enriched) as items
    FROM flattened_items
    GROUP BY transaction_id
)

-- Krok 3: Łączymy wszystko w finalny model
SELECT
    t.* EXCEPT(items),
    ai.items,
    c.first_name,
    c.last_name,
    c.email,
    c.registration_date
FROM transactions t
LEFT JOIN aggregated_items ai ON t.transaction_id = ai.transaction_id
LEFT JOIN customers c ON t.customer_id = c.customer_id
