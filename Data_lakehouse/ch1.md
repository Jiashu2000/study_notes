# Chapter 1: Describing Current Data Management Limitations

- This chapter describes **_how the approach to managing data has changed over time due to various factors_** and how these changes have pushed for new DM approaches to evolve.

- Some of these aspects include easier access to data, increased volume of data, the emergence of unstructured data, the need for speed in data preparation, and the necessity of reliable data pipelines that can constantly feed new types of use cases with data.

## Exploring Relational Databases

- In the early days of DM, the relational database was the primary method that companies used to collect, store, and analyze data. Relational databases offered a way for companies to store and analyze highly structured data about their customers using Structured Query Language (SQL).

- However, with the rise of the Internet, companies found themselves drowning in data. To store all this new data, a single database was no longer sufficient. Companies, therefore, often built multiple databases organized by lines of business to hold the data. But as the volume of data just continued to grow, companies often ended up with **_dozens of disconnected databases_** with different users and purposes, and many companies failed to turn their data into actionable insights.

## Sorting out Data Warehouses

- Companies ended up with decentralized, fragmented stores of data, called **_data silos_**, across the organization. Data warehouses were born to meet this need and to unite disparate databases across the organization.

- Limitations of Data Warehouses

    1. Data warehouses for a huge IT project can involve high maintenance costs.
    2. Data warehouses only support business intelligence (BI) and
    reporting use cases. There’s no capability for supporting ML use cases.
    3. Data warehouses lack scalability and flexibility when handling various sorts of data in a data warehouse.

## Diving into Data Lakes

- Apache Hadoop emerged as an open-source distributed data processing technology. Apache Hadoop is a collection of open-source software for big data analytics that allowed large data sets to be processed with clusters of computers working in parallel.

- Spark was the first unified analytics engine that facilitated largescale data processing, SQL analytics, and ML. Spark was also 100 times faster than Hadoop.

- Benefits:

    1. Companies could shift from expensive, proprietary data warehouse software to in-house computing clusters running on free and open-source Hadoop.
    2. It allowed companies to analyze massive amounts of unstructured data (big data) in a way that wasn’t possible before.

- Many modern data architectures use Spark as the processing engine that enables data engineers and data scientists to perform ETL, refine their data, and train ML models. Cheap blob storage (AWS S3 and Microsoft Azure Data Lake Storage) is how the data is stored in the cloud, and Spark has become the processing engine for transforming data and making it ready for BI and ML.

## Why a Traditional Data Lake is not Enough

- Problems

    1. They don’t support transactions
    2. They don’t enforce data quality.
    3. Their lack of consistency and isolation makes it almost impossible to mix appends and reads, and batch and streaming jobs.

- A common approach is to use multiple systems — a data lake, several data warehouses, and other specialized systems such as streaming, time-series, graph, and image databases to address the increasing needs


