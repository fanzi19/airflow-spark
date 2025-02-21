
from pyspark.sql import SparkSession
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("Starting Spark HDFS test from Airflow...")

spark = SparkSession.builder \
    .appName("SparkHDFSAirflowTest") \
    .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000") \
    .getOrCreate()

try:
    logger.info("Testing write to HDFS...")
    test_data = [("test1", 1), ("test2", 2), ("test3", 3)]
    df = spark.createDataFrame(test_data, ["name", "value"])
    df.write.mode("overwrite").parquet("hdfs://namenode:9000/test/airflow_test_data")
    logger.info("Successfully wrote to HDFS")

    logger.info("Testing read from HDFS...")
    read_df = spark.read.parquet("hdfs://namenode:9000/test/airflow_test_data")
    logger.info("Successfully read from HDFS:")
    read_df.show()

except Exception as e:
    logger.error(f"Error during HDFS operations: {str(e)}")
    raise e

finally:
    spark.stop()
