{{
    config(
        materialized='table'
    )
}}

SELECT * FROM {{ ref('prep_transactions_enriched') }}
