# Partition Shuffling

## Understanding Spark Partitions

- a node is a single machine in a spark cluster, and a spark cluster is a collection of these nodes that work together to process data.

- partition shuffling is essentially the process of **_redistributing data across nodes_**. this typically occurs during operations such as aggregations and joins, where data needs to be rerorganized so that related data ends up in the same partition.

- the problem with shuffling, however, is that it can be computationally expensive and can potentially lead to performance bottlenecks.

## Operations that Trigger Shuffling

- two things that cause shuffling:
    1. transformations that alter the structure of the data.
    2. actions that trigger a computation and return a result to the driver program.

- transformation that cause data shuffle:
    1. **_joins_**: when two dataframes are joined together, spark needs to ensure that rows with the same key from both dataframes are in the same partition. if they are not, spark will have to shuffle data.
    2. **_aggregation_**: operations such as groupbykey, reducebykey and groupby involve grouping data based on keys. these operations can cause a shuffle because spark needs to ensure that all data sharing the same key ends up in the same partition for aggregation.
    3. **_distinct_**: spark needs to shuffle the data across partitions to compare them. this operation brings potentially duplicates rows onto the same partition for comparison and removal.
    4. **_repartitioning_**: operations like repartition and coalesce reshuffle all the data. repartition increases or decreases the number of partitions, and coalesce combines existing partitions to reduce their number.

    ``` python
    df_repartitioned = df.repartition(5)
    df_coalesced = df_repartitioned.coalesce(2)
    ```

- in the context of data processing, a **_key_** is a specific field that is used to organize, sort, or combine data.

- shuffling can be expensive as it involves redistributing data across the network, and it should be minimized whenever possible. however, it it unavoidable in many cases.

## Strategies to Minimize Shuffling

#### Optimze your transformation

- choosing the right type of transformation can significantly reduce the amount of data that needs to be shuffled. for instance, use reducebykey to combine the output with the same key on each partition before shuffling.

#### Use broadcast joins

- broadcast joins are an excellent tool for handling joins between a large and small dataframe. when one dataframe is much smaller than the other, we can broadcast the smaller one to every node in the cluster.

- while it is recommended to let spark to decide whether to use a broadcast join or not, if you have clear knowledge about your data and its size, you can manuallyk instruct spark to use a broadcast join.

```python
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", -1)

from pyspark.sql.functions import broadcast

result = df1.join(broadcast(df2), df1['joinkey'] == df2['joinkey'])
```

#### Repartition smartly

- repartitioning your data to match the number of cores in your cluster can help you maximize resource utilization and minimize shuffling.

- having 2-3 tasks per cpu core in your cluster is often a good starting point. 

- if you are about to perform a join operation on a specific column, consider reparitioning on that column before the join.

```python
df_repartitioned_on_column = df.repartition("joinkey")
```

- if you have a large number of small partitions, consider using the **_coalesce_** function to reduce the number of partitions. coalesce avoids a full shuffle.

#### Shuffle partition count

- match the total data size: a common practice is to have each partition size ranging between **_100 mb to 200 mb_**. partitions of this size tend to avoid having too many small partitions (which can increase overhead due to task scheduling and result in underutilization of cpu resources) and having too few large partitions (which can lead to insufficient parallelism and out-of-memory errors).

- to get partitions to the right size: look for the largest stage in your spark job, and divide that stage's input size by your target partition size. for instance, if the biggest stage is taking in 50gb of data, you can get the partitions down to 200mb by dividing the input siz by 200.

- shuffle partition count: 500/200 = 250
```python
spark.conf.set("spark.sql.shuffle.partitins", 250)
```

- spark sets the number of partitions to 200 by default. the optimal number of partitions can vary greatly depending on the size and characteristics of your data, as well as the resources of your cluster.

#### Consider cluster resources

- a general rule is to have 2-3 tasks per cpu core in your cluster.

#### Monitor and adjust

- look at the size and number of shuffle read and write tasks. if you see some tasks are much larger than others, it might be a sign that you need more partitions. if many tasks are very small, you might have too many partitions.

## Examples

#### Spark rdd shuffle

``` scala

val spark: SparkSession = SparkSesson.builder()
        .master("local[5]")
        .appName("SparkByExamples.com")
        .getOrCreate()
    
val sc = spark.sparkContext

val rdd: RDD[String] = sc.textFile("src/main/resources/test.txt")

println("RDD Partition Count: "+ rdd.getNumPartitions)

val rdd2 = rdd.flatMap(f => f.split(" "))
    .map(m => (m,1))

val rdd5 = rdd2.reduceBykey(_ + _)

println("RDD Partition Count: "+ rdd5.getNumPartitions)

```

- both getNumPartitions from the above examples return the same number of partitions. though reduceByKey() triggers data shuffle, it does not change the partition count as rdd inherit the partition size from parent rdd 

#### Spark dataframe shuffle

```scala
import spark.implicits._

val simpleData = Seq(("James","Sales","NY",90000,34,10000),
    ("Michael","Sales","NY",86000,56,20000),
    ("Robert","Sales","CA",81000,30,23000),
    ("Maria","Finance","CA",90000,24,23000),
    ("Raman","Finance","CA",99000,40,24000),
    ("Scott","Finance","NY",83000,36,19000),
    ("Jen","Finance","NY",79000,53,15000),
    ("Jeff","Marketing","CA",80000,25,18000),
    ("Kumar","Marketing","NY",91000,50,21000)
  )

val df = simpleData.toDF("employee_name", "department", "state", "salary","age","bonus")

val df2 = df.groupby("state").count()

println(df2.rdd.getNumPartitions)

```

- unlike rdd, spark sql dataframe api increases the partitions when the transformation operation performs shuffling.

- DataFrame increases the partition number to 200 automatically when Spark operation performs data shuffling (join(), aggregation functions). This default shuffle partition number comes from Spark SQL configuration spark.sql.shuffle.partitions which is by default set to 200.

## References 

- https://medium.com/@tomhcorbin/boosting-efficiency-in-pyspark-a-guide-to-partition-shuffling-9a5af77703ea

- https://sparkbyexamples.com/spark/spark-shuffle-partitions/
