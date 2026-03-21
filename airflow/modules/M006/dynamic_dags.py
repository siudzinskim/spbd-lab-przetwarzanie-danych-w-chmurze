import pendulum
from airflow.decorators import dag, task
from airflow.utils.trigger_rule import TriggerRule

# Define a list of DAG configurations with relative start dates
dag_configs = [
    {
        'dag_id': 'dynamic_dag_1',
        'start_date': pendulum.today().subtract(days=1),  # Yesterday
        'schedule': '@daily'
    },
    {
        'dag_id': 'dynamic_dag_2',
        'start_date': pendulum.now().subtract(hours=1),  # One hour ago
        'schedule': '@hourly'
    },
    {
        'dag_id': 'dynamic_dag_3',
        'start_date': pendulum.today().subtract(weeks=2),  # Two weeks ago
        'schedule': '0 0 * * *'  # Every day at midnight
    }
]


# Function to create a DAG dynamically
def create_dag(dag_id, start_date, schedule):
    @dag(dag_id=dag_id, start_date=start_date, schedule=schedule, catchup=False, tags=['module 006', 'dynamic_dags'])
    def dynamic_dag():
        @task
        def generate_data():
            # Simulate generating some data (a list of numbers in this case)
            return [1, 2, 3, 4, 5]

        for item in [1,2,3,4,5]:
            for i in range(10000):
                @task(task_id=f'process_item_{item}_{i}')
                def process_item(item):
                    print(f"Processing item: {item} [{i}]")

                process_item(item)

        # create_dynamic_tasks(generate_data())

    return dynamic_dag()  # Call the function to create the DAG object


# Create DAGs dynamically based on the configurations
for config in dag_configs:
    globals()[config['dag_id']] = create_dag(
        config['dag_id'], config['start_date'], config['schedule']
    )
