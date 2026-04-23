from __future__ import annotations

import pendulum
import os

from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from airflow.models import Variable
from airflow.decorators import task
import duckdb

# --- Default Configuration ---
GENERATOR_SCRIPT_PATH = os.getenv('GENERATOR_SCRIPT_PATH', '/config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt01/generator.py')
DBT_BOOKSTORE_LAB_DIR = os.getenv('DBT_BOOKSTORE_LAB_DIR', '/tmp')

templated_date_nodash = "{{ ds_nodash }}"
templated_date_dash = "{{ ds }}"

templated_customers_output_file = f"{DBT_BOOKSTORE_LAB_DIR}/customers-{templated_date_nodash}.csv"
templated_transactions_output_file = f"{DBT_BOOKSTORE_LAB_DIR}/transactions-{templated_date_nodash}.json"
templated_offset = "{{ ti.execution_date.strftime('%Y%m%d%H%M%S') }}"

generate_data_command = (
    f"python {GENERATOR_SCRIPT_PATH} "
    f"--generate all "
    f"--customers-offset {templated_offset} "
    f"--transactions-offset {templated_offset} "
    f"--customers-output {templated_customers_output_file} "
    f"--transactions-output {templated_transactions_output_file} "
    f"--start-date {templated_date_dash} "
    f"--end-date {templated_date_dash}"
)

with DAG(
    dag_id='daily_data_generator',
    start_date=days_ago(1),
    schedule='@daily',
    catchup=False,
    max_active_runs=1,
    tags=['data-generation', 'dbt', 'daily'],
    description='Generates daily customer and transaction data and uploads to GCS.',
    default_args={'owner': 'airflow'},
) as dag:

    generate_daily_data_task = BashOperator(
        task_id='generate_daily_data',
        bash_command=generate_data_command,
    )

    verify_files_exist_task = BashOperator(
        task_id='verify_generated_files_exist',
        bash_command=(
            f"echo 'Verifying existence of generated files...' && "
            f"ls -l {templated_customers_output_file} && "
            f"ls -l {templated_transactions_output_file} && "
            f"echo 'Generated files found.'"
        ),
        doc_md=(
            "Verifies that the customer and transaction files for the execution date have been generated "
            "in the target directory. The task will fail if `ls` returns an error (e.g., file not found)."
        ),
    )

    # GCS Configuration (requires GCS_bucket_name variable in Airflow)
    try:
        GCS_BUCKET_NAME = Variable.get("GCS_bucket_name")
        
        gcs_customers_target_path = f"gs://{GCS_BUCKET_NAME}/data-lake/raw-data/customers/date={templated_date_dash}/customers-{templated_date_nodash}.csv"
        gcs_transactions_target_path = f"gs://{GCS_BUCKET_NAME}/data-lake/raw-data/transactions/date={templated_date_dash}/transactions-{templated_date_nodash}.json"
        
        upload_customers_to_gcs_task = BashOperator(
            task_id='upload_customers_to_gcs',
            bash_command=f"gsutil cp {templated_customers_output_file} {gcs_customers_target_path}",
        )

        upload_transactions_to_gcs_task = BashOperator(
            task_id='upload_transactions_to_gcs',
            bash_command=f"gsutil cp {templated_transactions_output_file} {gcs_transactions_target_path}",
        )

        @task
        def read_gcs_hive_and_export(ds, ds_nodash):
            import subprocess
            import shutil
            from google.cloud import storage
            from google.cloud import bigquery
            
            local_raw_dir = "/tmp/gcs_customers_raw"
            if os.path.exists(local_raw_dir):
                shutil.rmtree(local_raw_dir)
            os.makedirs(local_raw_dir)
            
            # Pobranie danych z GCS lokalnie
            gcs_src = f"gs://{GCS_BUCKET_NAME}/data-lake/raw-data/customers/"
            subprocess.run(["gsutil", "-m", "cp", "-r", gcs_src, local_raw_dir], check=True)
            
            # DuckDB scala wszystkich klientów
            con = duckdb.connect(database=':memory:', read_only=False)
            local_path_pattern = f"{local_raw_dir}/customers/date=*/*.csv"
            all_customers_csv = "/tmp/all_customers.csv"
            
            query = f"COPY (SELECT * FROM read_csv_auto('{local_path_pattern}', hive_partitioning=TRUE)) TO '{all_customers_csv}' (HEADER, DELIMITER ',');"
            con.sql(query)
            con.close()
            
            # Generowanie transakcji dla WSZYSTKICH klientów
            all_transactions_json = f"/tmp/all_customers_transactions-{ds_nodash}.json"
            books_input = os.path.join(os.path.dirname(GENERATOR_SCRIPT_PATH), "books.csv")
            
            gen_transactions_cmd = [
                "python", GENERATOR_SCRIPT_PATH,
                "--generate", "transactions",
                "--customers-input", all_customers_csv,
                "--transactions-output", all_transactions_json,
                "--books-input", books_input,
                "--start-date", ds,
                "--end-date", ds
            ]
            subprocess.run(gen_transactions_cmd, check=True)
            
            # Przesyłanie pliku do GCS za pomocą Python SDK (wymaga zainstalowanej biblioteki w obrazie)
            client = storage.Client()
            bucket = client.bucket(GCS_BUCKET_NAME)
            
            gcs_dest_path = f"data-lake/raw-data/transactions/date={ds}/all_customers_transactions-{ds_nodash}.json"
            blob = bucket.blob(gcs_dest_path)
            blob.upload_from_filename(all_transactions_json)
            print(f"Uploaded {all_transactions_json} to gs://{GCS_BUCKET_NAME}/{gcs_dest_path}")

        export_task = read_gcs_hive_and_export(ds="{{ ds }}", ds_nodash="{{ ds_nodash }}")

        generate_daily_data_task >> verify_files_exist_task >> [upload_customers_to_gcs_task, upload_transactions_to_gcs_task] >> export_task
    
    except Exception:
        # Fallback if variable is not yet defined to avoid breaking the parser completely
        generate_daily_data_task >> verify_files_exist_task
