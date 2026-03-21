from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

# Define default arguments for the DAG
args = {
    'owner': 'airflow',
    'start_date': datetime.now() - timedelta(weeks=1),
}

# Define the DAG with the following parameters:
# - dag_id: The unique identifier for the DAG.
# - default_args: The default arguments for the DAG.
# - schedule: The schedule for the DAG. In this case, it's set to None, meaning the DAG will not run on a schedule.
# - catchup: Whether to catch up on past runs. In this case, it's set to False, meaning the DAG will not run for past dates.
# - tags: A list of tags to categorize the DAG.
dag = DAG(
    dag_id='legacy_bash_dag_airflow',
    default_args=args,
    schedule=None,
    catchup=False,
    tags=['module 001', 'legacy']
)

# Define the first task, which prints a starting message.
start = BashOperator(
    task_id="start",
    bash_command="echo 'Starting the DAG'",
    dag=dag
)

# Define the first parallel task, which prints a message.
parallel_task_1 = BashOperator(
    task_id="parallel_task_1",
    bash_command="echo 'Executing parallel task 1'",
    dag=dag
)

# Define the second parallel task, which prints a message.
parallel_task_2 = BashOperator(
    task_id="parallel_task_2",
    bash_command="echo 'Executing parallel task 2'",
    dag=dag
)

# Define the third parallel task, which prints a message.
parallel_task_3 = BashOperator(
    task_id="parallel_task_3",
    bash_command="echo 'Executing parallel task 3'",
    dag=dag
)

# Define the last task, which prints an ending message.
end = BashOperator(
    task_id="end",
    bash_command="echo 'Ending the DAG'",
    dag=dag
)

# Define the task dependencies.
# The 'start' task runs first, followed by the three parallel tasks, and finally the 'end' task.
start >> [parallel_task_1, parallel_task_2, parallel_task_3] >> end
