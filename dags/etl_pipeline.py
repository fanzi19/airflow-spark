from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email': ['your-email@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'etl_pipeline',
    default_args=default_args,
    description='An ETL pipeline using PySpark',
    schedule_interval=timedelta(days=1),
)

# Extract task using PySpark
extract_task = SparkSubmitOperator(
    task_id='extract_data',
    application='/opt/airflow/dags/spark/extract.py',
    conn_id='spark_default',
    conf={
        'spark.master': 'spark://spark-master:7077',
        'spark.driver.memory': '1g',
        'spark.executor.memory': '1g',
    },
    dag=dag,
)

# Transform task using PySpark
transform_task = SparkSubmitOperator(
    task_id='transform_data',
    application='/opt/airflow/dags/spark/transform.py',
    conn_id='spark_default',
    conf={
        'spark.master': 'spark://spark-master:7077',
        'spark.driver.memory': '1g',
        'spark.executor.memory': '1g',
    },
    dag=dag,
)

# Load task using PySpark
load_task = SparkSubmitOperator(
    task_id='load_data',
    application='/opt/airflow/dags/spark/load.py',
    conn_id='spark_default',
    conf={
        'spark.master': 'spark://spark-master:7077',
        'spark.driver.memory': '1g',
        'spark.executor.memory': '1g',
    },
    dag=dag,
)

extract_task >> transform_task >> load_task
