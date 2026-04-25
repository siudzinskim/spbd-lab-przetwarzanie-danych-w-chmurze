SELECT
    transaction_id,
    customer_id,
    CAST(transaction_date AS DATE) as transaction_date,
    items,
    cash_register,
    cashier
FROM {{ source('gcs_raw', 'ext_transactions') }}
