#!/bin/bash
# Ustawienie AIRFLOW_HOME na folder zamontowany w wolumenie trwałym
export AIRFLOW_HOME=/config/workspace/airflow
mkdir -p $AIRFLOW_HOME
ln -s $AIRFLOW_HOME /config/airflow

echo "Inicjalizacja środowiska Airflow w $AIRFLOW_HOME..."

mkdir -p $AIRFLOW_HOME/dags
mkdir -p $AIRFLOW_HOME/logs
mkdir -p $AIRFLOW_HOME/plugins

# Kopiowanie konfiguracji
cp airflow.cfg $AIRFLOW_HOME/airflow.cfg
cp webserver_config.py $AIRFLOW_HOME/webserver_config.py

# Kopiowanie DAG-ów (w tym dbt_run_dag.py jeśli istnieje w głównym folderze)
cp -R dags/* $AIRFLOW_HOME/dags/ 2>/dev/null || true

echo "Uruchamianie migracji bazy danych..."
airflow db migrate

echo "Uruchamianie Airflow w trybie standalone..."
airflow standalone
