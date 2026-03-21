import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

with DAG(
        dag_id='sample_cli_commands',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 008', 'cli']
) as dag:
    print_date = BashOperator(
        task_id='print_date',
        bash_command='echo "{{ ds }}"',
    )


    def print_message(**context):
        message = context['dag_run'].conf.get('message', 'Default message')
        print(f"Message: {message}")


    print_message_task = PythonOperator(
        task_id='print_message',
        python_callable=print_message,
    )

    print_date >> print_message_task
