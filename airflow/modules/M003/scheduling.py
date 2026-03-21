from datetime import datetime, timedelta

from airflow.decorators import dag, task

# Calculate the start date as one week before the current date
start_date = datetime.now() - timedelta(weeks=1)
catchup_flag = True


# @daily
@dag(
    start_date=start_date,
    schedule="@daily",
    catchup=catchup_flag,
    tags=['module 003', 'taskflow', 'daily']
)
def taskflow_bash_dag_daily():
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    start >> [parallel_1, parallel_2, parallel_3] >> end


# @once
@dag(
    start_date=start_date,
    schedule="@once",
    catchup=catchup_flag,
    tags=['module 003', 'taskflow', 'once']
)
def taskflow_bash_dag_once():
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    start >> [parallel_1, parallel_2, parallel_3] >> end


# '0 */6 * * *' (every 6 hours)
@dag(
    start_date=start_date,
    schedule="0 */6 * * *",
    catchup=catchup_flag,
    tags=['module 003', 'taskflow', 'every_6_hours']
)
def taskflow_bash_dag_every_6_hours():
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    start >> [parallel_1, parallel_2, parallel_3] >> end


# '*/2 * * * *' (every 2 minutes)
@dag(
    start_date=start_date,
    schedule="*/2 * * * *",
    catchup=False,
    tags=['module 003', 'taskflow', 'every_2_minutes']
)
def taskflow_bash_dag_every_second_minute():
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    start >> [parallel_1, parallel_2, parallel_3] >> end


# @continuous
@dag(
    start_date=start_date,
    schedule="@continuous",
    catchup=False,
    max_active_runs=1,
    tags=['module 003', 'taskflow', 'continuous']
)
def taskflow_bash_dag_continuous():
    @task(task_id="start")
    def task_start():
        """
        This is the first task that prints a starting message.
        """
        print("Starting the DAG")

    @task(task_id="parallel_task_1")
    def task_parallel_1():
        """
        This is the first parallel task.
        """
        print("Executing parallel task 1")

    @task(task_id="parallel_task_2")
    def task_parallel_2():
        """
        This is the second parallel task.
        """
        print("Executing parallel task 2")

    @task(task_id="parallel_task_3")
    def task_parallel_3():
        """
        This is the third parallel task.
        """
        print("Executing parallel task 3")

    @task(task_id="end")
    def task_end():
        """
        This is the last task that prints an ending message.
        """
        print("Ending the DAG")

    start = task_start()
    parallel_1 = task_parallel_1()
    parallel_2 = task_parallel_2()
    parallel_3 = task_parallel_3()
    end = task_end()

    start >> [parallel_1, parallel_2, parallel_3] >> end


taskflow_bash_dag_daily()
taskflow_bash_dag_once()
taskflow_bash_dag_every_6_hours()
taskflow_bash_dag_continuous()
taskflow_bash_dag_every_second_minute()
