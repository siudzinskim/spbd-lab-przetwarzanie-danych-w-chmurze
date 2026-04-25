SELECT
    transaction_date,
    COUNT(DISTINCT transaction_id) as total_transactions,
    COUNT(DISTINCT customer_id) as total_customers,
    SUM(quantity) as total_items_sold,
    SUM(total_item_price) as total_revenue
FROM {{ ref('fct_transactions') }}
GROUP BY 1
ORDER BY 1 DESC
