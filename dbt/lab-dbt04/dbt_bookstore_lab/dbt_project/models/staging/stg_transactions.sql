-- models/staging/stg_transactions.sql
-- Model odczytujący dane bezpośrednio z pliku JSON przy użyciu funkcji DuckDB

{{
  config(
    materialized='table' 
  )
}}

select
   *
from read_json_auto('../data/transactions.json') -- Ścieżka względna do pliku JSON (od dbt_project/)