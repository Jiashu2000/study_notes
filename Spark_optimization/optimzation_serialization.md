# Spark Optimization: Serialization 

## Serialization

- serialization is the process of converting data structures or objects into a stream of bytes that can be transmitted or stored in a persistent medium.

- in spark, serialization is a key component of data transfer between the executor and driver nodes.


## Issues with Serialization

#### Inefficient Serialization Mechanism

- when using inefficient serialization mechanisms, such as java serialization, the process of serializing and deserializing data can be slow and lead to significant performance degradation.

#### Serialization Errors

- serialization errors can occur in spark when the object being serialized is not serializable, such as files or sockets, or when trying to serialize custom objects that have not been properly marked as serializable.

#### Serialization Overhead

- when invoking python udf in spark, data needs to be serialized from jvm objects to python objects, then spin up a python instance for processing. after processing it will then deserialize the results back to the jvm objects.

## Causes of Serialization

#### Data transfer/shuffling

- serialization is required when transfering data between nodes in a spark cluster during a shuffle or collect operation.

#### Caching data

- when data is cached, it needs to be serialized to disk or memory so that it can be efficiently retrieved when needed.

#### Data storage

- serialization is required when storing data in external storage system such as hdfs or amazon s3. when data is stored externally, it needs to be serialized into a format that can be stored and deserialized back into the original format when retrieved.

#### invoking python udfs

- serialization can occur when invoking python udfs in spark. when data is passed to a python udf for processing, it needs to be serialized into a format what can be processed by the python process.

## Solutions to Serialzation Issues

#### Employ efficient serialization mechanism

- apache spark provides efficient serialization mechanism, such as kryo, that can reduce the overhead of serilization and deserialization, by default, spark uses java serialization, which can slow and inefficient.

- to configure serializer to kryo

``` python
spark.conf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
```

- for larger datasets or more complex objects, increasing the Kyro buffer size may improve serialization performance.

```python
spark.kryoserializer.buffer.max = "128mb" # default: 64mb
```

#### Minimize Data Transfer/Shuffles

- serialization overhead can be reduced by minimizing data transfer between nodes in the spark cluster.

#### Use built-in spark functions instead of udf

- spark provides several built-in higher-order functions, such as reduce(), filter(), transform(), and map(),  which do not require serialization. by using these functions instead of user-defined functions, we can avoid serialization issues and improve the performance of their spark applications.

#### Use third-party libraries instead of udf

- third party libraries like apache arrow and koalas provide efficient serialization of python objects and pandas dataframe.

#### Use off-heap memory

- off-heap memory is the memory that is not managed by the jvm heap but rather allocated directly by the operating system.

- off-heap memory can help with serialization issues in spark by allowing the storage of serialized objects outside the jvm heap, which can help reduce memory pressure on the heap and improve the performance of serialization and deserialization operations.

- configure kyro serializer

```python
# configure kyro serializer
spark.conf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")

# configure kyro to use off-heap serialization
spark.conf.set("spark.kyro.unsafe", "true")
spark.conf.set("spark.kryo.referenceTracking", "true")

# enable spark to use off heap
spark.conf.set("spark.memory.offHeap.enabled", "true")
spark.conf.set("spark.memory.offHeap.size", "8g")

# cache data to off heap memory 
df.persist(storageLevel = "OFF_HEAP" )

```