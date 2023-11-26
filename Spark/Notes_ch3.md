# Chapter 3: Apache Spark's Structured APIs

## Spark: What’s Underneath an RDD?

- The RDD is the most basic abstraction in Spark. There are three vital characteristics associated with an RDD:

    - Dependencies: 
        
        a list of dependencies that instructs Spark how an RDD is constructed with its inputs is required

        When necessary to reproduce results, Spark can recreate an RDD from these dependencies and replicate operations on it. This characteristic gives RDDs resiliency.

    - Partitions (with some locality information):

        partitions provide Spark the ability to split the work to parallelize computation on partitions across executors.

        Spark will use locality information to send work to executors close to the data. That way less data is transmitted over the network.

    - Compute function: Partition => Iterator[T]:

        an RDD has a compute function that produces an Iterator[T] for the data that will be stored in the RDD.

- Couple of problems with this original model

    - For one, the compute function (or computation) is opaque to Spark. Spark does not know what you are doing in the compute function. Whether you are performing a join, filter, select, or aggregation, Spark only sees it as a lambda expression.

    - because it’s unable to inspect the computation or expression in the function, Spark has no way to optimize the expression—it has no comprehension of its intention

    - Another problem is that the Iterator[T] data type is also opaque for Python RDDs;

    - it has no idea if you are accessing a column of a certain type within an object. Therefore, all Spark can do is serialize the opaque object as a series of bytes, without using any data compression techniques.

## Structuring Spark

- One is to express computations by using common patterns found in data analysis. These patterns are expressed as high-level operations such as filtering, selecting, counting, aggregating, averaging, and grouping.

- This specificity is further narrowed through the use of a set of common operators in a DSL. Through a set of operations in DSL, available as APIs in Spark’s supported languages (Java, Python, Spark, R, and SQL), these operators let you tell Spark what you wish to compute with your data, and as a result, it can construct an efficient query plan for execution.

- And the final scheme of order and structure is to allow you to arrange your data in a tabular format, like a SQL table or spreadsheet, with supported structured data types

#### Key Merits and Benefits

- Structure yields a number of benefits, including better performance and space efficiency across Spark components

- expressivity, simplicity, composability, and uniformity.

- Demonstrate expressivity and composability: 

    If we were to use the low-level RDD API for this, the code would look as follows:

```PYTHON
# In python
# create an rdd of tuples (name, age)

dataRDD = sc.parallelize([("Brooke", 20), ("Denny", 31), ("Jules", 30), ("TD", 35), ("Brooke", 25)])

# Use map and reduceByKey transformations with their lambda
# expressions to aggregate and then compute average

agesRDD = (dataRDD
    .map(lambda x : (x[0], (x[1], 1)))
    .reduceByKey(lambda x, y: (x[0] + y[0], x[1], y[1]))
    .map(lambda x: (x[0], x[1][0]/x[1][1])))
```

- No one would dispute that this code, which tells Spark how to aggregate keys and compute averages with a string of lambda functions, is cryptic and hard to read. It’s completely opaque to Spark, because it doesn’t communicate the intention.

- By contrast, what if we were to express the same query with high-level DSL operators and the DataFrame API, thereby instructing Spark what to do?

```python
# in python

from pyspark.sql import SparkSession
from pyspark.sql.functions import avg

spark = (SparkSession
    .builder
    .appName("AuthorAges")
    .getOrCreate())

data_df = spark.createDataFrame([("Brooke", 20), ("Denny", 31), ("Jules", 30),("TD", 35), ("Brooke", 25)], ["name", "age"])

avg_df = data_df.groupBy('name').agg(avg("age"))

avg_df.show()
```
- we are using high-level DSL operators and APIs to tell Spark what to do. because Spark can inspect or parse this query and understand our intention, it can optimize or arrange the operations for efficient execution. Spark knows exactly what we wish to do

- Rest assured that you are not confined to these structured patterns; you can switch back at any time to the unstructured lowlevel RDD API.

- All of this simplicity and expressivity that we developers cherish is possible because of the Spark SQL engine upon which the high-level Structured APIs are built.

## The DataFrame API

- Inspired by pandas DataFrames in structure, format, and a few specific operations, Spark DataFrames are like distributed in-memory tables with named columns and schemas, where each column has a specific data type: integer, string, array, map, real, date, timestamp, etc. To a human’s eye, a Spark DataFrame is like a table

- DataFrames are immutable and Spark keeps a lineage of all transformations. You can add or change the names and data types of the columns, creating new DataFrames while the previous versions are preserved. A named column in a DataFrame and its associated Spark data type can be declared in the schema.

## Spark’s Basic Data Types

- Scala Data Type in Spark
- <img src = "pics/ch3/scala_data_type.png">

- Python Data Type in Spark
- <img src = "pics/ch3/python_data_type.png">

## Spark’s Structured and Complex Data Types

- Scala structured data types in Spark

- <img src = "pics/ch3/scala_structured_data_type.png">

- Python structured data types in Spark

- <img src = "pics/ch3/python_structured_data_type.png">

## Schemas and Creating DataFrames

- A schema in Spark defines the column names and associated data types for a DataFrame.

- Defining a schema up front as opposed to taking a schema-on-read approach offers three benefits:

    - You relieve Spark from the onus of inferring data types.
    - You prevent Spark from creating a separate job just to read a large portion of your file to ascertain the schema, which for a large data file can be expensive and time-consuming.
    - You can detect errors early if data doesn’t match the schema

#### Two ways to define a schema

- One is to define it programmatically
``` scala
// In Scala
Import org.apache.spark.sql.types._

val schema = StructType(Array(
    StructField("author", StringType, false),
    StructField("title", StringType, false),
    StructField("pages", IntegerType, false)
))
```

```python
# In Python
from pyspark.sql.types import *

schema = StructType([
    StructField("author", StringType(), False),
    StructField("title", StringType(), False),
    StructField("pages", IntegerType(), False),
])
```

- The other is to employ a Data Definition Language (DDL) string, which is much simpler and easier to read.

```scala
// In scala
val schema = "author STRING, title STRING, pages INT"
```

```python
# In Python
schema = "author STRING, title STRING, pages INT"
```

- Example: create_scheme.py

#### Columns and Expressions

- In Spark’s supported languages, columns are objects with public methods (represented by the Column type).



