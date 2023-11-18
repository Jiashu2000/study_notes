# Spark Optimization: Overview 

## Introduction

- as the size and complexity of data grows, spark application may face performance issues such as slow processing time, poor resource utilization, and scalability problem.

## The 5s Optimization Framework

- Shuffle
- Skew
- Spill
- Serialization
- Storage

## Shuffle

- shuffle is the process in apache spark in which data is exchanged and repartitioned between worker nodes during computation.

#### Issues

- high network utilization

- network bankwidth bottleneck

- uneven data distribution

#### Causes

- grouping and aggregation

- joins

- sorting

- repartitioning

#### Solutions

- minimizing data exchange over the network

-  broadcasting smaller tables

-  tuning the number of partitions

- use caching

## Skew

- data skew occurs when the data being processed is not evenly distributed across the worker nodes, which can lead to slower processing times and reduced efficiency.

#### Issues

- uneven execution time among tasks

- resources wastage on idling executors

#### Causes

- imbalanced data distribution

- data quality issues

- data shifts

- aggregation or joins

#### Solution

- salting techniques

- adaptive query engine (AQE)

- in-memory partitioning

- bucketing

## Spill

- data spill is an event in spark that occurs when there is inadequate space available to store data in an executor's memory. in this situation, spark writes the excess data from memory to disk. when spark needs to access the spilled data, it retrieves it from the disk.

#### Issues

- additional disk i/o overhead

- out-of-memory error

#### Causes

- insufficient memory allocation

- processing large datasets

- skewed data partitions

- complex data transformations

- large broadcast variables

#### Solution

- increase memory allocation

- partition tuning

- adaptive query engine

## Serialization

- serialization is the process of converting an object into a format that can be transmitted or stored. in spark, serialization is used to transfer data between nodes in the cluster during task execution and to store data on disk.

#### Issues

- inefficient serialization mechanism

- serialization errors

- serialization overhead

#### Causes

- data transfer/shuffling

- caching data

- data storage

- invoking python udfs

#### Solution

- employ efficient serialization mechanisms (kyro)

- minimize data transfer/shuffles

- use built-in spark functions instead of udfs

- use appropriate data types

- use apache arrow for serialization of python function

- use koala for serialization of pandas data frame

- use off-heap memory

## Storage

- in spark, storage refers to persisting data on external systems like hdfs or amazon s3, enabling more efficient and scalable data storage. however, the performance of storage can be affected by factors like file format, compression, and hardware specifications.

#### Issues

- slow read performance

- slow write performance

- high storage consumption

#### Causes

- unoptimized file format

- inefficient compression algorithm

- large file size

- a large number of small files

- inefficient storage hardware

- inefficient partitioning during data persistence

#### Solution

- use specialized storage formats (parquet, or)

- use appropriate compression algorithms (snappy, gzip)

- file size tuning

- use a distrited file system

## Summary

- to achieve optimal results, testing and experimentation are necessary, such as adjusting configuration parameters, trying combinations of different optimization techniques, and choosing the most cost-performance hardware.

- in summary, optimizing spark applications is crucial for achieving high performing, stable, and reliable data operations.

## Reference

- https://medium.com/@chenglong.w1/revamp-your-spark-performance-with-the-5s-optimization-framework-39742d8fa56b
