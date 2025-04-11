from __future__ import annotations

import pendulum
import os

from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator

# --- Default Configuration ---
# These values are used if not provided in the DAG Run Configuration (`dag_run.conf`)
# They are loaded into the DAG's 'params' for easier Jinja access
DEFAULT_DBT_PROJECT_DIR = os.getenv('DBT_PROJECT_DIR',
                                    '/config/workspace/dbt_bookstore_lab/dbt_project')  # !! CHANGE THIS DEFAULT !!
DEFAULT_DBT_PROFILES_DIR = os.getenv('DBT_PROFILES_DIR')  # Can be None if using default location
DEFAULT_DBT_TARGET = os.getenv('DBT_TARGET')  # Can be None if using default from profiles.yml
DEFAULT_DBT_MODELS = os.getenv('DBT_MODELS')  # Can be None to run all models
DEFAULT_DBT_EXCLUDE = os.getenv('DBT_EXCLUDE')  # Can be None to exclude nothing

# Base dbt command flags
DBT_BASE_COMMAND = "dbt --no-use-colors --no-write-json"
# --- /Default Configuration ---


# --- Templated Command Logic using Jinja ---
# Access dag_run.conf for runtime parameters, falling back to params (defaults)

# Use .get('key', params.default_key) to safely access config with fallback
templated_project_dir = "{{ dag_run.conf.get('dbt_project_dir', params.default_project_dir) }}"

# Construct optional flags only if values are provided
templated_profiles_dir_flag = "{% if dag_run.conf.get('dbt_profiles_dir', params.default_profiles_dir) %} --profiles-dir {{ dag_run.conf.get('dbt_profiles_dir', params.default_profiles_dir) }} {% endif %}"
templated_target_flag = "{% if dag_run.conf.get('dbt_target', params.default_target) %} --target {{ dag_run.conf.get('dbt_target', params.default_target) }} {% endif %}"
templated_select_flag = "{% if dag_run.conf.get('dbt_models', params.default_models) %} --select {{ dag_run.conf.get('dbt_models', params.default_models) }} {% endif %}"
templated_exclude_flag = "{% if dag_run.conf.get('dbt_exclude', params.default_exclude) %} --exclude {{ dag_run.conf.get('dbt_exclude', params.default_exclude) }} {% endif %}"
templated_full_refresh_flag = "{% if dag_run.conf.get('dbt_full_refresh', False) %} --full-refresh {% endif %}"  # Example for a boolean flag

# Build the command parts using the templates
bash_command_prefix = f"cd {templated_project_dir} && {DBT_BASE_COMMAND}"
# Flags common to most commands
common_flags = f"--project-dir {templated_project_dir}{templated_profiles_dir_flag}{templated_target_flag}"
# Flags specific to run/test (including model selection)
run_test_flags = f"{common_flags}{templated_select_flag}{templated_exclude_flag}"
# Flags for seed (potentially including full-refresh)
seed_flags = f"{common_flags}{templated_full_refresh_flag}"
# --- /Templated Command Logic ---


with DAG(
        dag_id='dbt_dag_run',
        start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),  # Adjust start date as needed
        schedule=None,  # Set to None for manual trigger with config
        catchup=False,
        tags=['dbt', 'elt', 'transform', 'parametrized'],
        description='Runs dbt workflow using parameters passed via DAG Run Configuration.',
        # Pass default values into params dictionary for access in Jinja templates
        params={
            'default_project_dir': DEFAULT_DBT_PROJECT_DIR,
            'default_profiles_dir': DEFAULT_DBT_PROFILES_DIR,
            'default_target': DEFAULT_DBT_TARGET,
            'default_models': DEFAULT_DBT_MODELS,
            'default_exclude': DEFAULT_DBT_EXCLUDE,
        },
        default_args={
            'owner': 'airflow',
        }
) as dag:
    dbt_seed_task = BashOperator(
        task_id='dbt_seed',
        bash_command=f"{bash_command_prefix} seed {seed_flags}",
        doc_md="Runs `dbt seed`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_full_refresh` from config.",
    )

    dbt_run_task = BashOperator(
        task_id='dbt_run',
        bash_command=f"{bash_command_prefix} run {run_test_flags}",
        doc_md="Runs `dbt run`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_models`, `dbt_exclude` from config.",
    )

    dbt_test_task = BashOperator(
        task_id='dbt_test',
        bash_command=f"{bash_command_prefix} test {run_test_flags}",
        doc_md="Runs `dbt test`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_models`, `dbt_exclude` from config.",
    )

    dbt_docs_generate_task = BashOperator(
        task_id='dbt_docs_generate',
        bash_command=f"{bash_command_prefix} docs generate {common_flags}",  # Docs usually don't use select/exclude
        doc_md="Runs `dbt docs generate`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target` from config.",
    )

    # --- Define Task Dependencies ---
    dbt_seed_task >> dbt_run_task >> dbt_test_task >> dbt_docs_generate_task