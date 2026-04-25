-- models/semantic/report_top_10_authors.sql
{{ config(materialized='table') }}

SELECT
    a.author_name,
    SUM(f.total_item_price) as total_revenue,
    SUM(f.quantity) as total_units_sold,
    COUNT(DISTINCT f.transaction_id) as total_transactions
FROM {{ ref('fct_transactions') }} f
JOIN {{ ref('dim_authors') }} a ON f.author_id = a.author_id
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 10
