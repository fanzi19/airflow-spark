from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    'spark_hdfs_test',
    default_args=default_args,
    description='Test Spark with HDFS',
    schedule_interval=None,
    catchup=False
)

# Create a test PySpark script
spark_script = """
from pyspark.sql import SparkSession

# Initialize Spark session with HDFS configuration
spark = SparkSession.builder \
    .appName("Spark HDFS Test") \
    .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000") \
    .getOrCreate()

# Create test data
data = [("Test1", 1), ("Test2", 2), ("Test3", 3)]
df = spark.createDataFrame(data, ["Name", "Value"])

# Write to HDFS
df.write.mode("overwrite").csv("hdfs://namenode:9000/user/airflow/test_output")

# Read from HDFS and show
df_read = spark.read.csv("hdfs://namenode:9000/user/airflow/test_output")
df_read.show()

spark.stop()
"""

# Save the script
with open('/opt/airflow/dags/spark_hdfs_test.py', 'w') as f:
    f.write(spark_script)

# Spark submit task
spark_test = SparkSubmitOperator(
    task_id='spark_hdfs_test',
    application='/opt/airflow/dags/spark_hdfs_test.py',
    conn_id='spark_default',
    application_args=[],
    conf={
        'spark.hadoop.fs.defaultFS': 'hdfs://namenode:9000',
        'spark.hadoop.yarn.resourcemanager.hostname': 'resourcemanager'
    },
    dag=dag
)
