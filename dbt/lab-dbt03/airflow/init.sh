#!/bin/bash
mkdir -p /config/airflow/dags/
cp airflow.cfg /config/airflow/airflow.cfg
cp webserver_config.py /config/airflow/webserver_config.py
cp -R dags/* /config/airflow/dags
airflow db migrate
airflow standalone