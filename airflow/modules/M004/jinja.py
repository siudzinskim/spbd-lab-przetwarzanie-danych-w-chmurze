from datetime import datetime

import pendulum
from airflow import DAG
from airflow.decorators import task
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator


# Define a custom macro to get XCom values
def get_xcom_value(task_ids, key, dag_id=None, run_id=None):
    """
    This macro retrieves an XCom value.
    """
    from airflow.models import DagRun, XCom
    execution_date = '{{ execution_date }}'
    dag_id = dag_id or '{{ dag.dag_id }}'
    run_id = run_id or '{{ run_id }}'
    dag_run = DagRun.find(dag_id=dag_id, run_id=run_id)[0]
    ti = dag_run.get_task_instance(task_ids)
    value = XCom.get_one(
        task_id=task_ids,
        dag_id=dag_id,
        execution_date=execution_date,
        key=key)
    return value


with DAG(
        dag_id='jinja_templating_demo',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        params={
            "file_name": "data.csv",
            "threshold": 100
        },
        user_defined_macros={
            'get_xcom_value': get_xcom_value
        },
        tags=['module 004', 'jinja']
) as dag:
    @task
    def generate_data():
        return [10, 20, 30, 40, 50]


    @task
    def process_data(data):
        total = sum(data)
        return total


    # BashOperator with Jinja templating
    bash_task = BashOperator(
        task_id='bash_task',
        bash_command="""
            echo "Processing file: {{ params.file_name }}"
            echo "Current date: {{ ds }}"
            echo "Data interval: {{ data_interval_start }} to {{ data_interval_end }}"
            echo "Threshold: {{ params.threshold }}"
        """
    )

    # PythonOperator with Jinja templating
    python_task = PythonOperator(
        task_id='python_task',
        python_callable=lambda: print(f"Hello from PythonOperator at {datetime.now()}!")
    )

    # Task to push an XCom value
    push_xcom_task = PythonOperator(
        task_id='push_xcom_task',
        python_callable=lambda ti: ti.xcom_push(key='my_value', value='XCom Value')
    )

    # BashOperator using a Jinja macro to read XCom
    read_xcom_task = BashOperator(
        task_id='read_xcom_task',
        bash_command='echo "XCom value: {{ ti.xcom_pull(task_ids=\"push_xcom_task\", key=\"my_value\") }}"'
    )

    data = generate_data()
    total = process_data(data)

    # BashOperator using Jinja to access the returned value from a TaskFlow task
    print_total_task = BashOperator(
        task_id='print_total_task',
        bash_command=f"echo 'Total from process_data: {total}'"
    )

    bash_task >> python_task >> push_xcom_task >> read_xcom_task >> print_total_task
