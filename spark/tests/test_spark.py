from pyspark.sql import SparkSession

def main():
    # Initialize Spark session with working directory configurations
    spark = SparkSession.builder \
        .appName("SparkHDFSTest") \
        .master("spark://spark-master:7077") \
        .config("spark.driver.host", "airflow-webserver") \
        .config("spark.driver.bindAddress", "0.0.0.0") \
        .config("spark.scheduler.mode", "FIFO") \
        .config("spark.scheduler.allocation.file", "") \
        .config("spark.dynamicAllocation.enabled", "false") \
        .config("spark.local.dir", "/tmp/spark-temp") \
        .config("spark.worker.dir", "/tmp/spark-worker") \
        .config("spark.executor.userClassPathFirst", "true") \
        .config("spark.driver.userClassPathFirst", "true") \
        .getOrCreate()

    try:
        print("SparkSession created successfully")
        print(f"Spark version: {spark.version}")
        print(f"Application ID: {spark.sparkContext.applicationId}")
        
        # Create a simple test DataFrame
        test_data = [("1", "Test1"), ("2", "Test2"), ("3", "Test3")]
        df = spark.createDataFrame(test_data, ["id", "value"])
        
        print("\nTest DataFrame:")
        df.show()
        
        test_path = "hdfs://namenode:9000/test/spark_test.parquet"
        
        # Create the directory in HDFS first
        hadoop_cmd = spark.sparkContext._jvm.org.apache.hadoop.fs.FileSystem.get(
            spark.sparkContext._jsc.hadoopConfiguration()
        )
        hadoop_cmd.mkdirs(
            spark.sparkContext._jvm.org.apache.hadoop.fs.Path("/test")
        )
        
        df.write.mode("overwrite").parquet(test_path)
        print(f"\nSuccessfully wrote data to {test_path}")
        
        df_read = spark.read.parquet(test_path)
        print("\nRead back from HDFS:")
        df_read.show()

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        raise
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
