
# Spark Optimization: Skew

## Skew

- skew is the result of the imbalance in size between the different partitions. small amounts of skew can be perfectly acceptable but in some circumstances, skew can result in spill and oom errors.

## Problems of Data Skew

- **_Straggling tasks_**

- **_Spills to disks and out of memory errors_**

## Example

- the following code add skew by replacing multiple pickup locations in the data with pickup location 237.

```python
from pyspark.sql import DataFrame, SparkSession
import pyspark.sql.functions as F

def prepare_trips_data(spark: SparkSession) -> DataFrame:

    pu_loc_to_change = [
        236, 132, 161, 186, 142, 141, 48, 239, 170, 162, 230, 163, 79, 234, 263, 140, 238, 107, 68, 138, 229, 249,
        237, 164, 90, 43, 100, 246, 231, 262, 113, 233, 143, 137, 114, 264, 148, 151
    ]
    
    res_df = spark.read\
        .parquet("data/trips/*.parquet")\ 
        .withColumn(
            "PULocationID",
            F.when(F.col("PULocationID").isin(pu_loc_to_change), F.lit(237))
            .otherwise(F.col("PULocationID"))
        )
    return res_df
```

## Detecting Data Skew: Putting the Spark UI to Use

- example calculation: the average distance traveled by pickup zone

```python

def join_on_skewed_data(spark: SparkSession):
    trips_data = prepare_trips_data(spark = spark)
    location_details_data = spark.read.options("header", True).csv("data/taxi+_zone_lookup.csv")

    trips_with_pickup_location_details = trips_data\
        .join(location_detail_data, F.col("PULocationID") == F.col("LocationID"), "inner")
    
    trips_with_pickup_location_details \
        .groupBy("Zone") \
        .agg(F.avg("trip_distance").alias("avg_trip_distance")) \
        .sort(F.col("avg_trip_distance").desc()) \
        .show(truncate = False, n = 1000)
    
    trips_with_pickup_location_details \
        .groupBy("Borough") \
        .agg(F.avg("trip_distance").alias("avg_trip_distance")) \
        .sort(F.col("avg_trip_distance").desc()) \
        .show(truncate = False, n = 1000)
    
```
- to observe the data skew and its consequences, adaptive query execution (AQE) needs to be disabled. additionally, broadcast join should be disabled as well.

```python
def create_spark_session_with_aqe_disabled() -> SparkSession:
    conf = SparkConf() \
        .set("spark.driver.memory" , "4G") \
        .set("spark.sql.autoBroadcastJoinThreshold", "-1") \
        .set("spark.sql.shuffle.partitions", "201") \
        .set("spark.sql.adaptive.enabled", "false")
    
    spark_session = SparkSession\
        .builder\
        .master("local[8]") \
        .config(conf=conf)\
        .appName("read from jdbc tutorial")
        .getOrCreate()
    
    return spark_session

if __name__ == "__main__": 
    start_time = time.time()
    spark = create_spark_session_with_aqe_disabled()
    
    join_on_skewed_data(spark = spark)

    print(f"Elapsed_time: {(time.time() - start_time)} seconds")
    time.sleep(10000)
```
- <img src = "pics/data_skew.png" width = 450/>
- one task taking significantly more time than all other task. it is in fact taking 7 seconds, wheras the median is 50 ms.
- the number of records processed by this task is significantly higher compared to other tasks. this is a straggling task.

## Addressing Data Skew

- there are general techniques that can be applied such as using the broadcast join where possible, or breaking up the skewed join column, as well as techniques that depend on the data, such as including another column in the join to better distribute the skewed data.

#### Dividing large paritions - using a derived column

- in the zone lookup data, which is smaller, repeat each row n times with a different value of a new column, which can have values 0 to n-1. This new column is called location_id_alt

- in the rides data, which is bigger, and is the one with data skew, add values 0 to n-1 basd on another column. In this example, I choose the pickup timestamp (tpep_pickup_datetime) column, convert it to day of the year using dayofyear spark sql function, and take a mod n. Now, both sides have an additional column, with values from 1 to n.

- adding this new column in the join will distribute all partitions, including the one with more data, into more partitions. the computation of the new column does not involve anything that would require a shuffle to compute, there is no rank or row number operation on a window.

```python

def join_on_skewed_data_with_subsplit(spark: SparkSession):
    subsplit_partitions = 20
    trips_data = prepare_trips_data(spark = spark)\
        .withColumn("dom_mod", F.dayofyear(F.col("tpep_pickup_datetime")))
        .withColumn("dom_mod", F.col("dom _mod")%subsplit_partitions)
    
    location_details_data = spark\
        .read\ 
        .option("header", True)\
        .csv("data/taxi+_zone_lookup.csv")\
        .withColumn("location_id_alt", F.array([F.lit(num) for num in range(0, subsplit_partitions)])) \
        .withColumn("location_id_alt", F.explode(F.col("location_id_alt")))
    
    trips_with_pickup_location_details = trips_data\
        .join( 
            location_details_data,
            (F.col('PULocationID') == F.col("LocationID")) & (F.col("location_id_alt") == F.col("dom_mod")),
            "inner"
        )
    
    trips_with_pickup_location_details\
        .groupBy("Zone") \
        .agg(F.avg("trip_distance").alias("avg_trip_distance")) \
        .sort(F.col("avg_trip_distance").desc()) \
        .show(truncate = False, n = 1000)
    
    trips_with_pickup_location_details \
        .groupBy("Borough") \
        .agg(F.avg("trip_distacne").alias("avg_trip_distance")) \
        .sort(F.col("avg_trip_distance").desc())\
        .show(truncate = False, n=1000)

```

- <img src ="pics/salting_skew.png" width = 450/>
- the longest task is now 2 seconds, and the median is 0.1 seconds.


#### Using adaptive query execution (AQE)

- AQE uses "statistics to choose the more efficient query execution plan" 

- ADE has a feature to handel skew by splitting long tasks called skewjoin. this can be enabled by setting the property "spark.sql.adaptive.skewjoin.enabled" to True. there are two parameters to tune skew join in AQE:
    1. spark.sql.adaptive.skewJoin.skewedPartitionFactor: this adjusts the factor by which if medium partition size is multiplied, partitions are considered as skewed partitions if they are larger than that.
    2. spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes: this is the minimum size of skewed partition, and it marks partitions as skewed if they larger than the value set for this parameter.

- there is another feature in AQE called Coalesce Partitions (spark.sql.adaptive.coaleascePartitions.enabled). when enabled, spark will tune the number of shuffle partitions based on statistics of data and processing resources, and it will also merge smaller partitions into larger partitions, reducing shuffle time and data transfer.

``` python

def create_spark_session_with_aqe_skew_join_enabled() -> SparkSession:
    conf = SparkConf() \
        .set("spark.driver.memory", "4G") \
        .set("spark.sql.autoBroadcastJoinThreshold", "-1") \
        .set("spark.sql.shuffle.partitions", "201") \ 
        .set("spark.sql.adaptive.enabled", "true") \
        .set("spark.sql.adaptive.coalescePartitions.enabled", "true")\
        .set("spark.sql.adaptive.skewJoin.enabled", "true") \
        .set("spark.sql.adaptive.skewJoin.skewedPartitionFactor", "3") \
        .set("spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes" "256K")
    
    spark_session = SparkSession \
            .builder \
            .master("local[8]") \
            .config(conf = conf) \
            .appName("Read from JDBC Tutorials") \
            .getOrCreate()

    return spark.session
```