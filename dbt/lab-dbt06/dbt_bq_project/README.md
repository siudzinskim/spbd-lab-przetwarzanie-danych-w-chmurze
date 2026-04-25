# Laboratorium 06: Praktyczna Implementacja DWH

W tym laboratorium budujemy kompletną strukturę Data Warehouse (DWH) przy użyciu dbt i BigQuery, przechodząc przez wszystkie warstwy przetwarzania danych.

## Cele Laboratorium:
1.  **Warstwa Staging (STG)**: Utworzenie widoków na surowych danych transakcyjnych.
2.  **Warstwa Prepared (PREP)**: Konsolidacja danych transakcyjnych i wzbogacenie ich o informacje o klientach (Wide Table).
3.  **Warstwa Materialized**:
    *   `nested_transactions`: Tabela zagnieżdżona (nested/repeated), zoptymalizowana pod BigQuery.
    *   `flat_transactions`: Tabela płaska (denormalizowana), zgodna z podejściem klasycznym.
4.  **Warstwa Core (DWH)**: Implementacja modelu Fact & Dimension (Star Schema) oraz podstawowych metryk biznesowych.

## Struktura Modelu:
- **Staging**: `stg_transactions`, `stg_customers`, `stg_books`.
- **Prepared (PREP)**: `prep_transactions_enriched`.
- **Core (DWH)**:
  - `dim_customers`: Wymiar klienta.
  - `dim_books`: Wymiar książki.
  - `dim_authors`: Wymiar autora.
  - `dim_publishers`: Wymiar wydawnictwa.
  - `fct_transactions`: Fakty sprzedażowe.
  - `metrics_daily_sales`: Agregacje dzienne.
  - `nested_transactions` / `flat_transactions`: Zmaterializowane widoki główne.
