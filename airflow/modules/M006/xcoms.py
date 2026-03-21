import pendulum
from airflow import DAG
from airflow.operators.python import PythonOperator


def push_xcom(**kwargs):
    ti = kwargs['ti']
    ti.xcom_push(key='message', value='Hello from Task A!')


def pull_xcom(**kwargs):
    ti = kwargs['ti']
    message = ti.xcom_pull(task_ids='push_xcom_task', key='message')
    print(f"Received XCom: {message}")


with DAG(
        dag_id='xcom_example',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 006', 'xcom']
) as dag:
    push_xcom_task = PythonOperator(
        task_id='push_xcom_task',
        python_callable=push_xcom,
    )

    pull_xcom_task = PythonOperator(
        task_id='pull_xcom_task',
        python_callable=pull_xcom,
    )

    push_xcom_task >> pull_xcom_task
