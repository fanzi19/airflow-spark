from pyspark.sql import SparkSession
import sys
import traceback

try:
    spark = SparkSession.builder \
        .appName("FairSchedulerTest") \
        .getOrCreate()

    print("SparkSession created successfully")
    
    # Create test data
    print("Creating test data...")
    data = range(1, 1000)
    df = spark.createDataFrame([(x, x * 2) for x in data], ["number", "double"])
    
    # Force an action to verify execution
    print("Counting records...")
    count = df.count()
    print(f"Total records: {count}")
    
    # Try some transformations
    print("Performing calculations...")
    result = df.groupBy().sum().collect()
    print("Calculations complete. Result:", result)
    
    spark.stop()

except Exception as e:
    print("ERROR DETAILS:")
    print("Exception type:", type(e).__name__)
    print("Exception message:", str(e))
    print("Full traceback:")
    traceback.print_exc()
    if 'spark' in locals():
        spark.stop()
    sys.exit(1)
