-- models/fact/fct_book_transactions.sql
-- Model faktów łączący transakcje z klientami i książkami

{{
  config(
    materialized='table' 
  )
}}

with transactions as (
    select *, unnest(items) as item from {{ ref('stg_transactions') }}
),
customers as (
    select * from {{ ref('stg_customers') }}
),
books as (
    select * from {{ ref('stg_books') }}
)

select
    t.transaction_id,
    t.transaction_date,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    b.book_id,
    b.title as book_title,
    b.author as book_author,
    t.item.unit_price as book_price,
    t.item.quantity as units,
    (t.item.unit_price * t.item.quantity) as total_amount
from transactions t
left join customers c on t.customer_id = c.customer_id
left join books b on t.item.book_id = b.book_id