-- models/semantic/report_sales_per_publisher.sql
{{ config(materialized='table') }}

SELECT
    p.publisher_name,
    SUM(f.total_item_price) as total_revenue,
    SUM(f.quantity) as total_units_sold,
    COUNT(DISTINCT f.transaction_id) as total_transactions
FROM {{ ref('fct_transactions') }} f
JOIN {{ ref('dim_publishers') }} p ON f.publisher_id = p.publisher_id
GROUP BY 1
ORDER BY total_revenue DESC
