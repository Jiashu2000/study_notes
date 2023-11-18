# Spark Optimization: Storage

## Storage

- In Apache Spark, storage refers to persisting data on external systems like HDFS or Amazon S3, enabling more efficient and scalable data storage.

- storage issues arise when data is stored on disk in a non-optimal way. issues related with storage can potentially cause excessive shuffle.

## Issues

#### Slow read performance

#### Slow write performance

#### High storage cost and consumption


## Causes

#### Data persisted in the inefficient format

- Spark works well with **_columnar data formats_**, such as Parquet and ORC, because they are optimized for efficient storage and analytical processing of large datasets. In contrast, data formats such as CSV or JSON are not optimized for storage and analytical workload, which can result in slower performance and take up more space.

#### Inefficient Data Compression and Decompression

#### Small file problem

- this is because reading a large number of small files can create lots of overheads and result in high disk I/O.

#### Inefficient Storage Hardware

- Storage issues can also be caused by inefficient hardware, such as slow hard drives or low memory

#### The Directory Scanning Issue

- another challenge arises when dealing with a large number directories. we could either have a long list of files in a single directory or in the case of highly partitioned datasets multiple levels folders.
scanning numerous directories can be time-consuming and impact the overall performance.

#### The Storage Schemas Issue

- depending on the file format used there can be different schema issues. for example, using json and csv the whole data needs to be read to infer data types. for parquet instead just a single file read is needed, but the whole list of parquet files needs to be read if we need to handle possible schema changes over time. in order to improve performance, we could provide schema definitions in advance.

## Solutions to Optimize Storage

#### Use Specialized Storage Formats

- Spark provides specialized storage formats, such as Parquet and ORC, that are optimized for efficient storage and analytical processing of large datasets.

#### Choose Appropriate Compression Algorithms

- Snappy is a good choice for frequently accessed data due to its faster decompression and query performance, while Gzip is better for infrequently accessed data due to its efficient storage and compression ratios.

#### File Size Tuning

- Merging small files into larger ones can reduce overhead and improve performance. We can use coalesce() or repartition() functions to reduce the number of partitions, and overwrites the data back to disk again.

#### Provide Schemas

- instead of relying on schema inference, explicitly provide schemas for your data. this allows spark to avoid the costly process of scanning the entire dataset.

#### Register as Tables

- by registering spark dataframes or datasets as tables in the metastore, you store the file location and schema inforamation. this reduces the need for repeated scanning and enhancing performance.

#### Utilize Delta

- apache spark delta lake provides an optimized storage layer for spark workloads. by using delta, you can take advantages of features like data skipping, file compaction, and optimized file formates.