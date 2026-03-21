import pendulum
from airflow import DAG
# from airflow.example_dags.example_branch_labels import describe
from airflow.models import Param
from airflow.operators.bash import BashOperator
from airflow.operators.python import BranchPythonOperator, ShortCircuitOperator


def choose_branch(**context):
    # value = context['dag_run'].conf.get('value', 1)
    value = int(context['params'].get('value', 1))
    if value > 5:
        return 'greater_than_5'
    else:
        return 'less_equal'


def check_condition(**context):
    # value = context['dag_run'].conf.get('value', 1)
    value = int(context['params'].get('value', 1))
    return value % 2 == 0  # Check if the value is even


with DAG(
        dag_id='branching_demo',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        params={"value": Param(1, type="integer")},
        tags=['module 006', 'branching']
) as dag:
    branch_task = BranchPythonOperator(
        task_id='branch_task',
        python_callable=choose_branch
    )

    greater_than_5 = BashOperator(
        task_id='greater_than_5',
        bash_command='echo "Executing Task A"'
    )

    less_euqal_5 = BashOperator(
        task_id='less_equal',
        bash_command='echo "Executing Task B"'
    )

    short_circuit_task = ShortCircuitOperator(
        task_id='short_circuit_task',
        python_callable=check_condition
    )

    even_number = BashOperator(
        task_id='even_number',
        bash_command='echo "Executing Task C"'
    )

    branch_task >> [greater_than_5, less_euqal_5]
    short_circuit_task >> even_number
