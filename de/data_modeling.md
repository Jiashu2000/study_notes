# Data Modeling

### 1. What is Data Modelling?

Data modeling is the process of creating a visual representation of data and its relationships to other data in a system. It is an important step in the design and development of databases, applications, and other data-intensive systems

Data modeling involves identifying the entities or objects in a system, and the relationships between them. Entities can be anything from customers and orders to products and transactions. Relationships describe how the entities are related to each other, such as a customer placing an order or a product being sold in a transaction.

Data modeling is important because it helps to ensure that data is consistent, accurate, and usable.

### 2. Describe various types of design schemas in Data Modelling.

- Star schema

In a star schema, data is organized around a central fact table, which contains the quantitative data that is being analyzed (such as sales or revenue). The fact table is surrounded by dimension tables, which contain descriptive information about the data (such as customer or product information). The dimension tables are connected to the fact table through foreign keys.

- Snowflake schema

A snowflake schema is similar to a star schema, but with more normalization of the dimension tables. This means that the dimension tables are broken up into sub-dimension tables, which are further normalized. 

Both star and snowflake schemas are designed for OLAP (Online Analytical Processing) systems, which are optimized for querying and analyzing large amounts of data. 