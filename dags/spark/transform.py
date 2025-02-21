# transform.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

def transform_data():
    spark = SparkSession.builder \
        .appName("Transform Data") \
        .getOrCreate()

    # Read extracted data
    data = spark.read.parquet("hdfs://namenode:9000/intermediate/extracted")
    
    # Apply transformations
    transformed = data.withColumn("processed_date", current_date())
    
    # Save transformed data
    transformed.write.parquet("hdfs://namenode:9000/intermediate/transformed")

if __name__ == "__main__":
    transform_data()
