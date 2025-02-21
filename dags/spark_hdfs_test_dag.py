from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 2, 14),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'spark_hdfs_test_dag',
    default_args=default_args,
    schedule='@daily',
    catchup=False
)

submit_spark_job = SparkSubmitOperator(
    task_id='submit_spark_job',
    application='/opt/spark/tests/test_spark.py',
    conn_id='spark_default',
    java_class=None,
    name='spark_hdfs_test',
    conf={
        'spark.master': 'spark://spark-master:7077',
        'spark.executor.memory': '1g',
        'spark.executor.cores': '1',
        'spark.driver.memory': '1g',
        'spark.submit.deployMode': 'client',
        'spark.driver.host': 'airflow-webserver',
        'spark.driver.bindAddress': '0.0.0.0',
        # Updated work directory settings
        'spark.worker.dir': '/opt/spark/work-dir',
        'spark.local.dir': '/opt/spark/work-dir',
        # Additional settings
        'spark.executor.extraJavaOptions': '-Djava.io.tmpdir=/opt/spark/work-dir',
        'spark.driver.extraJavaOptions': '-Djava.io.tmpdir=/opt/spark/work-dir',
        'spark.executor.userClassPathFirst': 'true',
        'spark.driver.userClassPathFirst': 'true',
        'spark.worker.cleanup.enabled': 'true',
        'spark.worker.cleanup.interval': '30',
        'spark.storage.cleanupFilesAfterExecutorExit': 'true',
        'spark.shuffle.service.enabled': 'false',
        'spark.dynamicAllocation.enabled': 'false',
        # Additional settings to handle directory issues
        'spark.local.directory': '/opt/spark/work-dir',
        'spark.executor.directories.allowNonExistent': 'true',
    },
    verbose=True,
    dag=dag
)

submit_spark_job 
