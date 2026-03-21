import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

with DAG(
        dag_id='docstring',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 008', 'docs'],
        doc_md="""
# My DAG Documentation

This is a **sample DAG** that demonstrates the use of Markdown in docstrings.

## Task Descriptions

* **Task A:** This task ...
* **Task B:** This task ...
        
        """
) as dag:
    task_a = BashOperator(
        task_id='tastk_a',
        bash_command='echo "{{ ds }}"',
    )

    task_b = BashOperator(
        task_id='tastk_b',
        bash_command='echo "{{ ds }}"',
    )
