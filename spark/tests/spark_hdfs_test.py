from pyspark.sql import SparkSession

print("Starting Spark HDFS test...")

# Create Spark session with cluster configuration
spark = SparkSession.builder     .appName("SparkHDFSTest")     .config("spark.scheduler.mode", "FIFO")     .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000")     .master("spark://spark-master:7077")     .getOrCreate()

try:
    print("Testing write to HDFS...")
    test_data = [("test1", 1), ("test2", 2)]
    df = spark.createDataFrame(test_data, ["name", "value"])
    df.write.mode("overwrite").parquet("hdfs://namenode:9000/test/test_data")
    print("Successfully wrote to HDFS")

    print("Testing read from HDFS...")
    read_df = spark.read.parquet("hdfs://namenode:9000/test/test_data")
    print("Successfully read from HDFS:")
    read_df.show()

except Exception as e:
    print("Error during HDFS operations:")
    print(str(e))
    import traceback
    traceback.print_exc()

finally:
    # Clean up
    spark.stop()
