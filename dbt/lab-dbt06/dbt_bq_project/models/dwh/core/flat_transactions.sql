{{
    config(
        materialized='table'
    )
}}

SELECT
    t.transaction_id,
    t.customer_id,
    t.transaction_date,
    t.cash_register,
    t.cashier,
    t.first_name,
    t.last_name,
    t.email,
    t.registration_date,
    item.book_id,
    item.book_title,
    item.book_author,
    ABS(FARM_FINGERPRINT(item.book_author)) as author_id,
    item.book_publisher,
    ABS(FARM_FINGERPRINT(item.book_publisher)) as publisher_id,
    item.book_category,
    item.unit_price,
    item.quantity,
    item.unit_price * item.quantity as total_item_price
FROM {{ ref('prep_transactions_enriched') }} t,
UNNEST(items) as item
