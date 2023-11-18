# Spark Optimization: Shuffle

## Shuffle

- shuffling is the process of exchanging data between partitions. spark does not move data between nodes randomly. shuffling is a time-consuming operation.

- <img src = "pics/shuffle.png" width = 450>

#### Performance Impacts 

- the shuffle is an expensive operation since it involves disk i/o, data serialization, and network i/o. to organize data for the shuffle, spark generates a set of tasks - map task to organize data, and a set of reduce tasks to aggregate it.

- internally, results from individual map tasks are kept in memory until they cannot fit. these are sorted based on the target partition and written to a single file.

- certain shuffle operations can consume significant amounts of heap memory since they employ in-memory data structures to organize records before or after transferring them. Shuffle also generates a large number of intermediate files on disks. 

## How to Avoid Spark Shuffle

#### Use Appropriate Partitioning:

- ensure that your data is appropriately partitioned from the begining. If your data is already partitioned based on operation you are performing, spark can avoid shuffling altogether. Use functions like repartition() or coaleace() to control the partitioning of your data.

``` python

data = [(1, "A"), (2, "B"), (3, "C"), (4, "D"), (5, "E")]

df = spark.createDataFrame(data, ['id', 'name'])

# bad - shuffling involved due to default partitioning (200 partitions)
result_bad = df.groupBy("id").count()

# good - avoids shuffling by explicitely repartitioning
df_repartitioned = df.repartition(2, "id")

result_good = df_repartitioned.groupBy("id").count()

```

#### Filter Early

- apply filters or conditions to your data as early as possible in your transformation. this way, you can reduce the amount of data that needs to be shuffled through the subsequent stages.

``` python

sales_data = [(101, "Product A", 100), (102, "Product B", 150), (103, "Product C", 200)]
categories_data = [(101, "Category X"), (102, "Category Y"), (103, "Category Z")]

sales_df = spark.createDataFrame(sales_data, ["product_id", "product_name", "price"])
categories_df = spark.createDataFrame(categories_data, ["product_id", "category"])

# bad - shuffling involved due to regular join
result_bad = sales_df.join(categories_df, on = 'product_id')

# good - avoid shuffling using broadcast variables
# filter the small dataframe early and broadcast it for efficient join
filter_categories_df = categories_df.filter("category = 'Category X'")
result_good = sales_df.join(broadcast(filter_categories_df), on = "product_id")

```

#### Use Broadcast Variables

- if you have small lookup data that you want to join with a larger dataset, consider using broadcast variables. broadcasting small dataset to all nodes can be more efficient than shuffling the larger dataset.

``` python
# Sample data
products_data = [(101, "Product A", 100), (102, "Product B", 150), (103, "Product C", 200)]
categories_data = [(101, "Category X"), (102, "Category Y"), (103, "Category Z")]

# Create DataFrames
products_df = spark.createDataFrame(products_data, ["product_id", "product_name", "price"])
categories_df = spark.createDataFrame(categories_data, ["category_id", "category_name"])

# bad - shuffling involved due to regular join
result_bad = products_df.join(categories_df, product_df.product_id == categories_df.category_id)

# good - avoids shuffling using broadcast variable
# create a broadcasr variable from the categories dataframe.
broadcast_categories = broadcast(categories_df)

result_good = products_df.join(broadcast_categories, product_df.product_id == broadcast_categories.category_id)

```

#### Avoid Using groupByKey()

- prefer reduceByKey() or aggregateByKey() instead of groupByKey() as the former performs partial aggregation locally before shuffling the data, leading to better performance.

```python
# Sample data
data = [(1, "click"), (2, "like"), (1, "share"), (3, "click"), (2, "share")]

rdd = sc.parallelize(data)

# bad - shuffling involved due to groupByKey
result_bad = rdd.groupByKey().mapValues(len)

# good - avoid shuffling by using reduceByKey
result_good = rdd.map(lambda x: (x[0], 1)).reduceByKey(lambda a, b: a+b)
```

#### Use Data Locality

- whenever possible, try to process data that is already stored on the same node where the computation is happening. this reduces network communication and shuffling.

```python
# Sample data
data = [(1, 10), (2, 20), (1, 5), (3, 15), (2, 25)]

df = spark.createDataFrame(data, ['key', 'value'])

# bad = shuffling involved due to default data locality
result_bad = df.groupBy("key").max("value")

# good - avoid shuffling by repartitioning and using data locality .
df_repartitioned = df.repartition("key") # repartition to align dat by key
result_good = df_repartitioned.groupBy("key").max("value")
```

- shuffle versus repartition: 
    1. shuffle: A shuffle is a process of redistributing data across the nodes in a cluster during certain operations, such as groupByKey or reduceByKey. It is typically necessary when the data needs to be rearranged or grouped differently based on certain keys, and the original data distribution across nodes is no longer suitable for the computation.
    2. Repartition:  Repartitioning is a specific operation that changes the number of partitions in a Resilient Distributed Dataset (RDD) or a DataFrame. The goal of repartitioning is to optimize the distribution of data across the cluster by changing the number of partitions. It allows you to control the parallelism of your computation and can be used to balance the workload across the nodes more evenly.

#### Use Memory and Disk Caching

- caching intermediate data that will be reused in multiple stages can help avoid recomputation and reduce the need for shuffling.

``` python

# Sample data
data = [(1, 10), (2, 20), (1, 5), (3, 15), (2, 25)]

df = spark.createDataFrame(data, ['key', 'value'])

# bad - shuffling involved due to recomputation of the filter condition
result_bad = df.filter("value > 10").groupBy("key").sum("value")

# good - avoids shuffling by caching the filtered data
df_filtered = df.filter("value > 10").cache()
result_good = df_filtered.groupBy('key').sum("value")
```

#### Optimize Data Serialization

- choose efficient serialization formats like Avro or Kryo to reduce the data size during shuffling.

``` python
spark = SparkSession.builder \
    .appName("AvoidShuffleExample") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .getOrCreate()
```

#### Tune Spark Configuration

- adjust spark configuration parameters like spark.shuffle.partitions, spark.reducer.maxSizeInFlight, and spark.shuffle.file.buffer to fine tune the shuffling behavior.

#### Monitor and Analyze

- use spark ui and spark history server to analyze the performance of your jobs.

- shuffling may still be unavoidable, especially for complex operations or when working with large databases. In such cases, focus on optimizing shuffling rather than completely avoiding it. 