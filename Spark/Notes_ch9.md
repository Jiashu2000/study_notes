# Chapter 9. Building Reliable Data Lakes with Apache Spark

- For a data engineer, data scientist, or data analyst, the ultimate goal of building pipelines is to query the processed data and get insights from it.

## The Importance of an Optimal Storage Solution

- Scalability and performance

    The storage solution should be able to scale to the volume of data and provide the read/write throughput and latency that the workload requires.

- Transaction support

    Complex workloads are often reading and writing data concurrently, so support for ACID (Atomicity, Consistency, Isolation, and Durability) transactions is essential to ensure the quality of the end results.

- Support for diverse data formats

    The storage solution should be able to store unstructured data (e.g., text files like raw logs), semi-structured data (e.g., JSON data), and structured data (e.g., tabular data).

- Support for diverse workloads

    - SQL workloads like traditional BI analytics
    - Batch workloads like traditional ETL jobs processing raw unstructured data
    - Streaming workloads like real-time monitoring and alerting
    - ML and AI workloads like recommendations and churn predictions

- Openness

    Standard APIs allow the data to be accessed from a variety of tools and engines. This allows the business to use the most optimal tools for each type of workload and make the best business decisions

## Databases

#### A Brief Introduction to Databases

- Databases are designed to store structured data as tables, which can be read using SQL queries. The data must adhere to a strict schema, which allows a database management system to heavily co-optimize the data storage and processing.

- SQL workloads on databases can be broadly classified into two categories

    - Online transaction processing (OLTP) workloads
        
        Like bank account transactions, OLTP workloads are typically high-concurrency, low-latency, simple queries that read or update a few records at a time.

    - Online analytical processing (OLAP)

        OLAP workloads, like periodic reporting, are typically complex queries (involving aggregates and joins) that require high-throughput scans over many records.

#### Reading from and Writing to Databases Using Apache Spark

- Apache Spark can connect to a wide variety of databases for reading and writing data. For databases that have JDBC drivers (e.g., PostgreSQL, MySQL), you can use the built-in JDBC data source along with the appropriate JDBC driver jars to access the data.

#### Limitations of Databases

- Growth in data sizes

    With the advent of big data, there has been a global trend in the industry to measure and collect everything (page views, clicks, etc.) in order to understand trends and user behaviors

    As a result, the amount of data collected by any company or organization has increased from gigabytes a couple of decades ago to terabytes and petabytes today.

- Growth in the diversity of analytics

    there is a need for deeper insights. This has led to an explosive growth of complex analytics like machine learning and deep learning

- Databases are extremely expensive to scale out

    most databases, especially the open source ones, are not designed for scaling out to perform distributed processing

- Databases do not support non.SQL based analytics very well

    This means other processing tools, like machine learning and deep learning systems, cannot efficiently access the data (except by inefficiently reading all the data from the database). Nor can databases be easily extended to perform non–SQL based analytics like machine learning.

## Data Lakes

- In contrast to most databases, a data lake is a distributed storage solution that runs on commodity hardware and easily scales out horizontally.

#### A Brief Introduction to Data Lakes

- The data lake architecture, unlike that of databases, decouples the distributed storage system from the distributed compute system.

- Organizations build their data lakes by independently choosing the following:

    1. Storage system
    
        They choose to either run HDFS on a cluster of machines or use any cloud object store (e.g., AWS S3, Azure Data Lake Storage, or Google Cloud Storage).

    2. File format

        Depending on the downstream workloads, the data is stored as files in either structured (e.g., Parquet, ORC), semi-structured (e.g., JSON), or sometimes even unstructured formats (e.g., text, images, audio, video).
    
    3. Processing engine(s)

        Again, depending on the kinds of analytical workloads to be performed, a processing engine is chosen. This can either be a batch processing engine (e.g., Spark, Presto, Apache Hive), a stream processing engine (e.g., Spark, Apache Flink), or a machine learning library (e.g., Spark MLlib, scikit-learn, R).

- This flexibility—the ability to choose the storage system, open data format, and processing engine that are best suited to the workload at hand—is the biggest advantage of data lakes over databases.

#### Reading from and Writing to Data Lakes using Apache Spark

- Support for diverse workloads

    Spark provides all the necessary tools to handle a diverse range of workloads, including batch processing, ETL operations, SQL workloads using Spark SQL, stream processing using Structured Streaming (discussed in Chapter 8), and machine learning using MLlib (discussed in Chapter 10), among many others

- Support for diverse file formats

    In Chapter 4, we explored in detail how Spark has built-in support for unstructured, semi-structured, and structured file formats.

- Support for diverse filesystem

    Spark supports accessing data from any storage system that supports Hadoop’s FileSystem APIs. Since this API has become the de facto standard in the big data ecosystem, most cloud and on-premises storage systems provide implementations for it—which means Spark can read from and write to most storage systems.

#### Limitations of Data Lakes

- Data lakes are not without their share of flaws, the most egregious of which is the lack of transactional guarantees.

    1. Atomicity and isolation

        Processing engines write data in data lakes as many files in a distributed manner. If the operation fails, there is no mechanism to roll back the files already written, thus leaving behind potentially corrupted data.

        (the problem is exacerbated when concurrent workloads modify the data because it is very difficult to provide isolation across files without higher-level mechanisms).
    
    2. Consistency

        Lack of atomicity on failed writes further causes readers to get an inconsistent view of the data. In fact, it is hard to ensure data quality even in successfully written data. For example, a very common issue with data lakes is accidentally writing out data files in a format and schema inconsistent with existing data
    
- To work around these limitations of data lakes, developers employ all sorts of tricks. Here are a few examples: 

    - Large collections of data files in data lakes are often “partitioned” by subdirectories based on a column’s value (e.g., a large Parquet-formatted Hive table partitioned by date). To achieve atomic modifications of existing data, often entire subdirectories are rewritten (i.e., written to a temporary directory, then references swapped) just to update or delete a few records.

    - The schedules of data update jobs (e.g., daily ETL jobs) and data querying jobs (e.g., daily reporting jobs) are often staggered to avoid concurrent access to the data and any inconsistencies caused by it.

## Lakehouses: The Next Step in the Evolution of Storage Solutions

- The lakehouse is a new paradigm that combines the best elements of data lakes and data warehouses for OLAP workloads. Lakehouses are enabled by a new system design that provides data management features similar to databases directly on the low-cost, scalable storage used for data lakes

- Features

    - Transaction support:

        Similar to databases, lakehouses provide ACID guarantees in the presence of concurrent workloads.

    - Schema enforcement and governance

        Lakehouses prevent data with an incorrect schema being inserted into a table, and when needed, the table schema can be explicitly evolved to accommodate ever-changing data.

        The system should be able to reason about data integrity, and it should have robust governance and auditing mechanisms.

    - Support for diverse data types in open formats

        Unlike databases, but similar to data lakes, lakehouses can store, refine, analyze, and access all types of data needed for many new data applications, be it structured, semi-structured, or unstructured.

    - Support for diverse workloads

        lakehouses enable diverse workloads to operate on data in a single repository. Breaking down isolated data silos (i.e., multiple repositories for different categories of data) enables developers to more easily build diverse and complex data solutions, from traditional SQL and streaming analytics to machine learning.

    - Support for upserts and deletes

        Complex use cases like change-data-capture (CDC) and slowly changing dimension (SCD) operations require data in tables to be continuously updated. Lakehouses allow data to be concurrently deleted and updated with transactional guarantees.

    - Data governance

        Lakehouses provide the tools with which you can reason about data integrity and audit all the data changes for policy compliance.
    
- Apache Hudi, Apache Iceberg, and Delta Lake, that can be used to build lakehouses with these properties. They are all open data storage formats that do the following:

    - Store large volumes of data in structured file formats on scalable filesystems.

    - Maintain a transaction log to record a timeline of atomic changes to the data(much like databases).

    - Use the log to define versions of the table data and provide snapshot isolation guarantees between readers and writers.

    - Support reading and writing to tables using Apache Spark.

#### Apache Hudi

- Initially built by Uber Engineering, Apache Hudi—an acronym for Hadoop Update Delete and Incremental—is a data storage format that is designed for incremental upserts and deletes over key/value-style data

- Besides the common features mentioned earlier, it supports:

    - Upserting with fast, pluggable indexing
    - Atomic publishing of data with rollback support
    - Reading incremental changes to a table
    - Savepoints for data recovery
    - File size and layout management using statistics
    - Async compaction of row and columnar data

#### Apache Iceberg

- Originally built at Netflix, Apache Iceberg is another open storage format for huge data sets. However, unlike Hudi, which focuses on upserting key/value data, Iceberg focuses more on general-purpose data storage that scales to petabytes in a single table and has schema evolution properties. Specifically, it provides the following additional features (besides the common ones):

    - Schema evolution by adding, dropping, updating, renaming, and reordering of columns, fields, and/or nested structures
    - Hidden partitioning, which under the covers creates the partition values for rows in a table
    - Partition evolution, where it automatically performs a metadata operation to update the table layout as data volume or query patterns change
    - Time travel, which allows you to query a specific table snapshot by ID or by timestamp
    - Rollback to previous versions to correct errors
    - Serializable isolation, even between multiple concurrent writers

#### Delta Lake

- Delta Lake is an open source project hosted by the Linux Foundation, built by the original creators of Apache Spark.

- Similar to the others, it is an open data storage format that provides transactional guarantees and enables schema enforcement and evolution. It also provides several other interesting features, some of which are unique. Delta Lake supports:

    - Streaming reading from and writing to tables using Structured Streaming sources and sinks

    - Update, delete, and merge (for upserts) operations, even in Java, Scala, and Python APIs

    - Schema evolution either by explicitly altering the table schema or by implicitly merging a DataFrame’s schema to the table’s during the DataFrame’s write. (In fact, the merge operation in Delta Lake supports advanced syntax for conditional updates/inserts/deletes, updating all columns together, etc., as you’ll see later in the chapter.)

    - Time travel, which allows you to query a specific table snapshot by ID or by timestamp

    - Rollback to previous versions to correct errors

    - Serializable isolation between multiple concurrent writers performing any SQL, batch, or streaming operations

- Of these three systems, so far Delta Lake has the tightest integration with Apache Spark data sources (both for batch and streaming workloads) and SQL operations (e.g., MERGE)

## Building Lakehouses with Apache Spark and Delta Lake

- In this section, we are going to take a quick look at how Delta Lake and Apache Spark can be used to build lakehouses. Specifically, we will explore the following:

    - Reading and writing Delta Lake tables using Apache Spark

    - How Delta Lake allows concurrent batch and streaming writes with ACID guarantees

    - How Delta Lake ensures better data quality by enforcing schema on all writes, while allowing for explicit schema evolution

    - Building complex data pipelines using update, delete, and merge operations, all of which ensure ACID guarantees

    - Auditing the history of operations that modified a Delta Lake table and traveling back in time by querying earlier versions of the table

#### Configuring Apache Spark with Delta Lake

#### Loading Data into a Delta Lake Table

```scala
val source_path = "/databricks-datasets/learning-spark-v2/loans/
loan-risks.snappy.parquet"

val delta_path = "/tmp/loans_delta"

// Create the Delta table with the same loans data
spark
    .read
    .format("parquet")
    .load(source_path)
    .write
    .format("delta")
    .save(delta_path)

// Create a view on the data called loans_delta
spark
    .read
    .format("delta")
    .load(delta_path)
    .createOrReplaceTempView("loans_delta")

// now we can read and explore the data as easily as any other table
spark
    .sql("select count(*) from loans_delta").show()
```

#### Loading Data Streams into a Delta Lake Table

```scala 
import org.apache.spark.sql.streaming._

val newLoanStreamDF = ... // Streaming DataFrame with new loans data
val checkpointDir = ... // Directory for streaming checkpoints
val streamingQuery = newLoanStreamDF.writeStream
    .format("delta")
    .option("checkpointLocation", checkpointDir)
    .trigger(Trigger.ProcessingTime("10 seconds"))
    .start(deltaPath)
```

- Delta Lake has a few additional advantages over traditional formats like JSON, Parquet, or ORC:

    1. It allows writes from both batch and streaming jobs into the same table



    2. It allows multiple streaming jobs to append data to the same table

        Delta Lake’s metadata maintains transaction information for each streaming query, thus enabling any number of streaming queries to concurrently write into a table with exactly-once guarantees.

    3. It provides ACID guarantees even under concurrent write

#### Enforcing Schema on Write to Prevent Data Corruption

- A common problem with managing data with Spark using common formats like JSON, Parquet, and ORC is accidental data corruption caused by writing incorrectly formatted data. Since these formats define the data layout of individual files and not of the entire table, there is no mechanism to prevent any Spark job from writing files with different schemas into existing tables. This means there are no guarantees of consistency for the entire table of many Parquet files.

- The Delta Lake format records the schema as table-level metadata. If it is not compatible, Spark will throw an error before any data is written and committed to the table, thus preventing such accidental data corruption.

- Let’s test this by trying to write some data with an additional column, closed, that signifies whether the loan has been terminated. Note that this column does not exist in the table:

```scala
// In Scala
val loanUpdates = Seq(
    (1111111L, 1000, 1000.0, "TX", false),
    (2222222L, 2000, 0.0, "CA", true))
    .toDF("loan_id", "funded_amnt", "paid_amnt", "addr_state", "closed")

loanUpdates.write.format("delta").mode("append").save(deltaPath)
```

#### Evolving Schemas to Accommodate Changing Data

- In our world of ever-changing data, it is possible that we might want to add this new column to the table. This new column can be explicitly added by setting the option "mergeSchema" to "true"

```scala
loanUpdates.write.format("delta").mode("append")
    .option("mergeSchema","true")
    .save(delta_path)
```
- With this, the column will be added to the table schema, and new data will be closed appended. When existing rows are read, the value of the new column is considered as NULL.

- In Spark 3.0, you can also use the SQL DDL command to add and ALTER TABLE modify columns.

#### Transforming Existing Data

- Delta Lake supports the DML commands UPDATE, DELETE, and MERGE, which allow you to build complex data pipelines.

    1. Updating data to fix errors

        Suppose, upon reviewing the data, we realized that all of the loans assigned to addr_state = 'OR' should have been assigned to addr_state = 'WA'. If the loan table were a Parquet table, then to do such an update we would need to:

        - copy all of the rows that are not affected into a new table.
        - Copy all of the rows that are affected into a DataFrame, then perform the data modification.
        - Insert the previously noted DataFrame’s rows into the new table.
        - Remove the old table and rename the new table to the old table name.

        In Spark 3.0, which added direct support for DML SQL operations like UPDATE, DELETE, and MERGE, instead of manually performing all these steps you can simply run the SQL UPDATE command.

        ```scala
        import io.delta.tables.DeltaTable
        import org.apache.spark.sql.functions._

        val deltaTable = DeltaTable.forPath(spark, deltaPath)
        deltaTable.update(
            col("addr_state") === "OR",
            Map("addr_state" -> lit("WA"))
        )
        ```

    2. Deleting user-related data

        Say it is mandated that you have to delete the data on all loans that have been fully paid off.

        ```scala
        // In Scala
        val deltaTable = DeltaTable.forPath(spark, deltaPath)
        deltaTable.delete("funded_amnt >= paid_amnt")
        ```

    3. Upserting change data to a table using merge()

        To continue with our loan data example, say we have another table of new loan information, some of which are new loans and others of which are updates to existing loans. In addition, let’s say this changes table has the same schema as the loan_delta table. You can upsert these changes into the table using the DeltaTable.merge() operation, which is based on the MERGE SQL command.

        ```scala
        deltaTable
            .alias("t")
            .merge(loanUpdates.alias("s"), "t.loan_id = s.loan_id")
            .whenMatched.updateAll()
            .whenNotMatched.insertAll()
            .execute()
        ```

        Furthermore, if you have a stream of such captured changes, you can continuously apply those changes using a Structured Streaming query.

    4. Deduplicating data while inserting using insert-only merge

        The merge operation in Delta Lake supports an extended syntax beyond that specified by the ANSI standard, including advanced features like the following:

        - Delete actions
        
            For example, MERGE ... WHEN MATCHED THEN DELETE.

        - Clause conditions
            
            For example, MERGE ... WHEN MATCHED AND <condition> THEN ....
        
        - Optional actions
            
            All the MATCHED and NOT MATCHED clauses are optional.

        - Star syntax

            For example, UPDATE * and INSERT * to update/insert all the columns in the target table with matching columns from the source data set. The equivalent Delta Lake APIs are updateAll() and insertAll()
    
        ```scala
        deltaTable
            .alias("t")
            .merge(historicalUpdates.alias("s"), "t.loan_id = s.loan_id")
            .whenNotMatched.insertAll()
            .execute()
        ```

#### Auditing Data Changes with Operation History

- All of the changes to your Delta Lake table are recorded as commits in the table’ transaction log. As you write into a Delta Lake table or directory, every operation is automatically versioned

- You can query the table’s operation history as noted in the following code snippet:

```scala
// In Scala/Python
deltaTable.history().show()

deltaTable
    .history(3)
    .select("version", "timestamp", "operation", "operationParameters")
    .show(false)
```

#### Querying Previous Snapshots of a Table with Time Travel

- You can query previous versioned snapshots of a table by using the DataFrameReader options "versionAsOf" and "timestampAsOf".

```scala
spark.read
    .format("delta")
    .option("timestampAsOf", "2020-01-01") // timestamp after table creation
    .load(deltaPath)

spark.read.format("delta")
    .option("versionAsOf", "4")
    .load(deltaPath)
```
- This is useful in a variety of situations
    - Reproducing machine learning experiments and reports by rerunning the job on a specific table version
    - Comparing the data changes between different versions for auditing
    - Rolling back incorrect changes by reading a previous snapshot as a DataFrame and overwriting the table with it

## Summary

Delta Lake, a file-based open source storage format that, along with Apache Spark, is a great building block for lakehouses. As you saw, it provides the following:

- Transactional guarantees and schema management, like databases
- Scalability and openness, like data lakes
- Support for concurrent batch and streaming workloads with ACID guarantees
- Support for transformation of existing data using update, delete, and merge operations that ensure ACID guarantees
- Support for versioning, auditing of operation history, and querying of previous versions