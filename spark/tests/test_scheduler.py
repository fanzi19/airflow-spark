from pyspark.sql import SparkSession

# Create Spark session
spark = SparkSession.builder     .appName("FairSchedulerTest")     .getOrCreate()

# Set the pool for this job
spark.sparkContext.setLocalProperty("spark.scheduler.pool", "production")

# Create test data
data = [(i, f"value_{i}") for i in range(1000)]
df = spark.createDataFrame(data, ["id", "value"])

# Perform some operations
result = df.groupBy("value").count()
result.show(5)

# Keep the application running for a while to check the UI
import time
time.sleep(60)

spark.stop()
