import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator


def set_variable(**kwargs):
    Variable.set('shared_message', 'Hello from DAG 1!')


with DAG(
        dag_id='variables_1_set_variable',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 004', 'variables']
) as dag:
    set_var_task = PythonOperator(
        task_id='set_variable',
        python_callable=set_variable
    )


def use_variable(**kwargs):
    shared_value = Variable.get('shared_message')
    print(f"Shared variable value: {shared_value}")


with DAG(
        dag_id='variables_2_use_variable',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 004', 'variables']
) as dag:
    use_var_task = PythonOperator(
        task_id='use_variable',
        python_callable=use_variable
    )
