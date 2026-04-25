SELECT
    customer_id,
    first_name,
    last_name,
    email,
    registration_date
FROM {{ ref('stg_customers') }}
