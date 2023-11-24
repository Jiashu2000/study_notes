
## Lab1: Exploring an Ecommerce Dataset Using SQL in Google BigQuery


#### 1. Write a query that shows total unique visitors

``` sql
select
    count(*) as product_views,
    count(distinct fullVisitorId) as unique_visitors
from data_to_insights.ecommerce.all_sessions;
```
#### 2. Now write a query that shows total unique visitors(fullVisitorID) by the referring site (channelGrouping)

```sql
select
    count(distinct fullVisitorId) as unique_visitors,
    channelGrouping
from data_to_insights.ecommerce.all_sessions
group by channelGrouping
order by channelGrouping DESC;
```

#### 3. Write a query to list all the unique product names (v2ProductName) alphabetically:

``` sql
select
    v2ProductName as productname
from data_to_insights.ecommerce.all_sessions
group by productname
order by productname;
```

#### 4. Write a query to list the five products with the most views (product_views) from all visitors 

- (include people who have viewed the same product more than once). Your query counts number of times a product (v2ProductName) was viewed (product_views), puts the list in descending order, and lists the top 5 entries:

```sql
select
    v2productname, 
    count(*) as product_views
from data_to_insights.ecommerce.all_sessions
where type = 'PAGE'
group by v2productName
order by product_views desc
limit 5;
```

#### 5. Refine the query to no longer double-count product views for visitors who have viewed a product many times.

- Each distinct product view should only count once per visitor.

```sql 
with unique_product_views_by_person as (

    select
        fullVisitorId,
        v2productname as product_name
    from data_to_insights.ecommerce.all_sessions
    where type = 'PAGE'
    group by fullVisitorId, v2productname
)

select
    count(*) as unique_view_count,
    product_name
from unique_product_views_by_person
group by product_name
order by unique_view_count desc
limit 5
```
#### 6. Expand your previous query to include the total number of distinct products ordered and the total number of total units ordered (productQuantity):

```SQL
select
    count(*) as product_views,
    count(productQuantity) as orders,
    sum(productQuantity) as quantity_product_ordered,
    v2ProductName
from data_to_insights.ecommerce.all_sessions
where type = 'PAGE'
group by v2ProductName
order by product_views desc
limit 5
```
#### 7. Expand the query to include the average amount of product per order (total number of units ordered/total number of orders, or SUM(productQuantity)/COUNT(productQuantity)):

```sql
select
    count(*) as product_views,
    count(productQuantity) as orders,
    sum(productQuantity) as quantity_product_ordered,
    sum(productQuantity)/count(productQuantity) as avg_per_order,
    v2productname as product_name
from data_to_insights.ecommerce.all_sessions
where type = 'PAGE'
group by v2ProductName
order by product_views desc
limit 5
```

#### Challenge 1: calculate a conversion rate

Write a conversion rate query for products with these qualities:
- More than 1000 units were added to a cart or ordered
- AND are not frisbees

Answer these questions:
- How many distinct times was the product part of an order (either complete or incomplete order)?
- How many total units of the product were part of orders (either complete or incomplete)?
- Which product had the highest conversion rate?

```sql
select
    count(*) as product_views,
    count(productquantity) as potential_orders,
    sum(productquantity) as quantity_product_added,
    (count(productquantity)/count(*)) as conversion_rate
from data_to_insights.ecommerce.all_sessions
where v2productname not like '%frisbee%'
group by v2productname
having quantity_product_added > 1000
order by conversion_rate
limit 10
```

#### Challenge 2: track visitor checkout progress

Write a query that shows the eCommerceAction_type and the distinct count of fullVisitorId associated with each type.

```sql
select
    count(distinct fullVisitorId) as number_of_unique_visitors,
    ecommerceAction_type 
from data_in_insights.ecommerce.all_sessions
group by ecommerceAction_type
order by ecommerceAction_type
```

You are given this mapping for the action type: Unknown = 0 Click through of product lists = 1 Product detail views = 2 Add product(s) to cart = 3 Remove product(s) from cart = 4 Check out = 5 Completed purchase = 6 Refund of purchase = 7 Checkout options = 8

- Use a Case Statement to add a new column to your previous query to display the eCommerceAction_type label (such as “Completed purchase”).

```sql
SELECT
  COUNT(DISTINCT fullVisitorId) AS number_of_unique_visitors,
  eCommerceAction_type,
  CASE eCommerceAction_type
  WHEN '0' THEN 'Unknown'
  WHEN '1' THEN 'Click through of product lists'
  WHEN '2' THEN 'Product detail views'
  WHEN '3' THEN 'Add product(s) to cart'
  WHEN '4' THEN 'Remove product(s) from cart'
  WHEN '5' THEN 'Check out'
  WHEN '6' THEN 'Completed purchase'
  WHEN '7' THEN 'Refund of purchase'
  WHEN '8' THEN 'Checkout options'
  ELSE 'ERROR'
  END AS eCommerceAction_type_label
FROM `data-to-insights.ecommerce.all_sessions`
GROUP BY eCommerceAction_type
ORDER BY eCommerceAction_type;

```

#### Challenge 3: Track abandoned carts from high quality sessions

- Write a query using aggregation functions that returns the unique session IDs of those visitors who have added a product to their cart but never completed checkout (abandoned their shopping cart).

```sql
select
    concat(fullVisitorId, cast(visitorId as string)) as unique_session_id,
    sessionQualityDim,
    sum(productRevenue) as transaction_revenue,
    max(eCommerceAction_type) as check_progress
from data_to_insights.ecommerce.all_sessions
where sessionQualityDim > 60
group by unique_session_id, sessionQualityDim
having
    check_progress = '3'
    and (transaction_revenuew = 0 or transaction_revenue is null)
```