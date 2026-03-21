from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.subdag import SubDagOperator
from datetime import datetime

# Define the SubDAG
def subdag_function(parent_dag_name, child_dag_name, args):
    with DAG(
        dag_id=f'{parent_dag_name}.{child_dag_name}',  # Correct dag_id formation
        start_date=args['start_date'],
        schedule=args['schedule'],
        catchup=args['catchup']
    ) as subdag:
        task_a = BashOperator(
            task_id='task_a',
            bash_command='echo "Task A in SubDAG"'
        )
        task_b = BashOperator(
            task_id='task_b',
            bash_command='echo "Task B in SubDAG"'
        )
        task_a >> task_b
    return subdag

with DAG(
    dag_id='subdag_example',
    start_date=datetime(2024, 11, 4),
    schedule=None,
    catchup=False,
    tags=['module 006', 'subdags']
) as dag:
    start_task = BashOperator(
        task_id='start_task',
        bash_command='echo "Start"'
    )

    subdag_task = SubDagOperator(
        task_id='subdag_task',
        subdag=subdag_function(
            parent_dag_name='subdag_example',
            child_dag_name='subdag_task',  # Now matches task_id
            args={'start_date': dag.start_date, 'schedule': dag.schedule_interval, 'catchup': dag.catchup}
        )
    )

    end_task = BashOperator(
        task_id='end_task',
        bash_command='echo "End"'
    )

    start_task >> subdag_task >> end_task