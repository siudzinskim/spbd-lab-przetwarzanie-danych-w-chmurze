from datetime import datetime, timedelta

from airflow.decorators import dag, task


# Define the DAG with the following parameters:
# - start_date: The date when the DAG should start running.
# - schedule: The schedule for the DAG. In this case, it's set to None, meaning the DAG will not run on a schedule.
# - catchup: Whether to catch up on past runs. In this case, it's set to False, meaning the DAG will not run for past dates.
# - tags: A list of tags to categorize the DAG.
@dag(
    start_date=datetime.now() - timedelta(weeks=1),
    schedule=None,
    catchup=False,
    tags=['module 001', 'taskflow']
)
def taskflow_bash_dag():
    # Define the first task, which prints a starting message.
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    # Define the first parallel task, which prints a message.
    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    # Define the second parallel task, which prints a message.
    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    # Define the third parallel task, which prints a message.
    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    # Define the last task, which prints an ending message.
    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    # Create instances of the tasks.
    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    # Define the task dependencies.
    # The 'start' task runs first, followed by the three parallel tasks, and finally the 'end' task.
    end.set_upstream(
        [
            parallel_1,
            parallel_2,
            parallel_3
        ]
    )
    start.set_downstream(
        [
            parallel_1,
            parallel_2,
            parallel_3
        ]
    )

taskflow_bash_dag()
