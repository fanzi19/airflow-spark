
from pyspark.sql import SparkSession

# Initialize Spark session with HDFS configuration
spark = SparkSession.builder     .appName("Spark HDFS Test")     .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000")     .getOrCreate()

# Create test data
data = [("Test1", 1), ("Test2", 2), ("Test3", 3)]
df = spark.createDataFrame(data, ["Name", "Value"])

# Write to HDFS
df.write.mode("overwrite").csv("hdfs://namenode:9000/user/airflow/test_output")

# Read from HDFS and show
df_read = spark.read.csv("hdfs://namenode:9000/user/airflow/test_output")
df_read.show()

spark.stop()
