import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.operators.python import BranchPythonOperator
from airflow.utils.trigger_rule import TriggerRule

# Trigger Rules
with DAG(
        dag_id='trigger_rules_demo',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 006', 'conditionals']
) as dag:
    task_a = BashOperator(
        task_id='task_a',
        bash_command='echo "Task A"'
    )
    task_b = BashOperator(
        task_id='task_b',
        bash_command='exit 1'  # This task will fail
    )
    cleanup_task = BashOperator(
        task_id='cleanup_task',
        bash_command='echo "Cleanup"',
        trigger_rule=TriggerRule.ALL_DONE
    )
    [task_a, task_b] >> cleanup_task

# Conditional Branching
with DAG(
        dag_id='conditional_branching_demo',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 006', 'conditionals']
) as dag:
    def choose_branch(**context):
        value = context['dag_run'].conf.get('value', 1)
        if value > 5:
            return 'task_a'
        else:
            return 'task_b'


    branch_op = BranchPythonOperator(
        task_id='choose_branch',
        python_callable=choose_branch
    )

    task_a = BashOperator(
        task_id='task_a',
        bash_command='echo "Executing Task A"'
    )

    task_b = BashOperator(
        task_id='task_b',
        bash_command='echo "Executing Task B"'
    )

    branch_op >> [task_a, task_b]

# Setup and Teardown
with DAG(
        dag_id='setup_teardown_demo',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 006', 'conditionals']
) as dag:
    create_resource = BashOperator(
        task_id='create_resource',
        bash_command='echo "Creating resource"'
    )

    use_resource = BashOperator(
        task_id='use_resource',
        bash_command='echo "Using resource"'
    )

    delete_resource = EmptyOperator(task_id='delete_resource')
    delete_resource.as_teardown(setups=create_resource)

    create_resource >> use_resource >> delete_resource

# Latest Only
with DAG(
        dag_id='latest_only_demo',
        # set start_date to 7 days ago
        start_date=pendulum.today('UTC').subtract(days=7),
        schedule='@daily',
        catchup=True,
        tags=['module 006', 'conditionals']
) as dag:
    latest_only_task = LatestOnlyOperator(task_id='latest_only_task')
    task_a = BashOperator(
        task_id='task_a',
        bash_command='echo "Task A"'
    )
    latest_only_task >> task_a

# Depend on Past
with DAG(
        dag_id='depend_on_past_demo',
        # set start_date to 7 days ago
        start_date=pendulum.today('UTC').subtract(days=7),
        schedule='@daily',
        catchup=True,
        tags=['module 006', 'conditionals']
) as dag:
    task_a = BashOperator(
        task_id='task_a',
        bash_command='echo "Task A"',
        depends_on_past=True
    )
