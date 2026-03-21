from datetime import datetime

from airflow import DAG
from airflow.models.param import Param
from airflow.operators.bash import BashOperator

with DAG(
        dag_id='param_demo',
        start_date=datetime(2024, 10, 12),
        schedule=None,
        catchup=False,
        tags=['module 004', 'params'],
        params={
            "data_source": Param("table_a", enum=["table_a", "table_b"]),
            "output_format": Param("csv", enum=["csv", "json"])
        }
) as dag:
    extract_data = BashOperator(
        task_id='extract_data',
        bash_command='echo "Extracting data from {{ params.data_source }}"',
    )

    format_data = BashOperator(
        task_id='format_data',
        bash_command="""
            echo "Formatting data as {{ params.output_format }}"
            if [ "{{ params.data_source }}" == "table_a" ]; then
              if [ "{{ params.output_format }}" == "csv" ]; then
                echo "id,name,value"
                echo "1,apple,10"
                echo "2,banana,20"
                echo "3,cherry,30"
              elif [ "{{ params.output_format }}" == "json" ]; then
                echo '[
                  {"id": 1, "name": "apple", "value": 10},
                  {"id": 2, "name": "banana", "value": 20},
                  {"id": 3, "name": "cherry", "value": 30}
                ]'
              fi
            elif [ "{{ params.data_source }}" == "table_b" ]; then
              if [ "{{ params.output_format }}" == "csv" ]; then
                echo "id,item,quantity"
                echo "101,pen,50"
                echo "102,paper,100"
                echo "103,eraser,75"
              elif [ "{{ params.output_format }}" == "json" ]; then
                echo '[
                  {"id": 101, "item": "pen", "quantity": 50},
                  {"id": 102, "item": "paper", "quantity": 100},
                  {"id": 103, "item": "eraser", "quantity": 75}
                ]'
              fi
            fi
        """
    )

    extract_data >> format_data

with DAG(
        dag_id='param_validation_demo',
        start_date=datetime(2024, 10, 12),
        schedule=None,
        catchup=False,
        tags=['module 004', 'params'],
        params={
            "email_address": Param("test@example.com", type="string", format="idn-email", minLength=8),
            "enum": Param("foo", type="string", enum=["foo", "bar", 42]),
            "value": Param("2024", type="integer", minimum=1972, maximum=2100),
        }
) as dag:
    print_params = BashOperator(
        task_id='print_params',
        bash_command="""
            echo "Email: {{ params.email_address }}"
            echo "Enum: {{ params.enum }}"
            echo "Value: {{ params.value }}"
        """
    )
