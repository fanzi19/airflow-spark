# extract.py
from pyspark.sql import SparkSession

def extract_data():
    spark = SparkSession.builder \
        .appName("Extract Data") \
        .getOrCreate()

    # Example: Read data from a source
    data = spark.read.csv("hdfs://namenode:9000/raw/input.csv")
    
    # Save to intermediate location
    data.write.parquet("hdfs://namenode:9000/intermediate/extracted")

if __name__ == "__main__":
    extract_data()
