# load.py
from pyspark.sql import SparkSession

def load_data():
    spark = SparkSession.builder \
        .appName("Load Data") \
        .getOrCreate()

    # Read transformed data
    data = spark.read.parquet("hdfs://namenode:9000/intermediate/transformed")
    
    # Load to final destination
    data.write.mode("overwrite").parquet("hdfs://namenode:9000/warehouse/final")

if __name__ == "__main__":
    load_data()
