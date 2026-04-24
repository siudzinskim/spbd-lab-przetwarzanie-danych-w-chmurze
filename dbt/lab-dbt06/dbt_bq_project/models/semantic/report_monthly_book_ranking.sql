-- models/semantic/report_monthly_book_ranking.sql
{{ config(materialized='table') }}

WITH monthly_sales AS (
    SELECT
        FORMAT_DATE('%Y-%m', transaction_date) as sales_month,
        book_id,
        book_title,
        SUM(total_item_price) as total_revenue,
        SUM(quantity) as total_units_sold
    FROM {{ ref('fct_transactions') }}
    GROUP BY 1, 2, 3
),

ranked_books AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY sales_month ORDER BY total_units_sold DESC) as monthly_rank
    FROM monthly_sales
)

SELECT * FROM ranked_books
ORDER BY sales_month DESC, monthly_rank ASC
