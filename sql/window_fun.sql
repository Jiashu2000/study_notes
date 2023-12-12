select
	`Customer Name`,
    Segment,
    sum(profit) as TotalProfits
from super_store
group by 1, 2;

/*
Window function example: FIRST_VALUE()

- first_value(): extracts the first value obtained by the expression calculated in the window.
- over: allows you to define the calculation window.
- partition by: defines which column the window will apply.
- range: allows limiting the frame.
*/

select
	customer_name,
    total_profit,
    segment,
    first_value(customer_name) over(
		partition by segment
        order by total_profit
        range between unbounded preceding and unbounded following
	) as worst_customer_on_segment
from (
	select
		`Customer Name` as customer_name,
		segment,
		sum(profit) as total_profit
	from
	 super_store
	 group by 1, 2
) as profits_per_customer;

/*
Window function example: LAST_VALUE()
*/

select
	customer_name,
    segment,
    total_profit,
    last_value(customer_name) over (
		partition by segment
        order by total_profit
        range between unbounded preceding and unbounded following
    ) as best_customer_on_segment
from (
	select
		`Customer Name` as customer_name,
		segment,
		sum(profit) as total_profit
	from super_store
	group by 1, 2
) as profits_per_customer;


/*
Define windows with the window expression
*/

select
	customer_name,
    total_profit,
    segment,
    first_value(customer_name) over profits_per_segment as worst_on_segment,
    last_value(customer_name) over profits_per_segment as best_on_segment
from (
	select
		`Customer Name` as customer_name,
		segment,
		sum(profit) as total_profit
	from
		super_store
	group by 1, 2
) as profit_per_customer
WINDOW profits_per_segment as (
	partition by segment
    order by total_profit
    range between unbounded preceding and unbounded following
);

/* 
Lead(), Lag()
*/

with 
sales_per_month
as (
select
	sum(sales) as sales,
    year(order_date) as year,
    quarter(order_date) as quarter,
    month(order_date) as month
from (
	select
     sales,
     str_to_date(`Order Date`, '%d/%m/%Y') as order_date
    from
	super_store
) t
group by
    year(order_date),
    quarter(order_date),
    month(order_date)
order by
    year(order_date),
    quarter(order_date),
    month(order_date)
)

select 
*
from sales_per_month;

/*
LAG(expression, [,offset], [,default_value]) over w
expression: a column or the result of a selection;
offset: the number of offset rows (1 otherwise);
default_value: if the row does not exist, a default value (null otherwise);
*/

with sales_per_year
as (
	select
		year(order_date) as year,
        sum(sales) as sales,
        lag(sum(sales), 1, 0) over w as previous_year_sales,
        sum(sales) - lag(sum(sales), 1, 0) over w as yoy
    from (
		select
			sales,
			str_to_date(`Order Date`, "%d/%m/%Y") as order_date
		from super_store
    ) t
    group by
		year(order_date) 
	window w as (
		order by year(order_date)
	)
)
select *
from sales_per_year;


with sales_per_month_over_years
as (
	select
		year(order_date) as year,
        month(order_date) as month,
        sum(sales) as sales,
        lag(sum(sales), 1, 0) over w as previous_year_month_sales,
        sum(sales) - lag(sum(sales), 1, 0) over w as moy
    from (
		select
			sales,
			str_to_date(`Order Date`, "%d/%m/%Y") as order_date
		from super_store
    ) t
    group by
		year(order_date), 
        month(order_date)
	window w as (
		partition by
			month(order_date)
		order by 
			year(order_date),
            month(order_date)
	)
    order by
		year(order_date), 
        month(order_date)
)
select
	year,
    month,
    sales,
    previous_year_month_sales,
    moy
from sales_per_month_over_years;

with month_sales 
as (
	select
		year(order_date) as year,
        month(order_date) as month,
        sum(sales) as sales
    from (
		select
			sales,
			str_to_date(`Order Date`, "%m/%d/%Y") as order_date
		from super_store
    ) t 
    group by
		year(order_date),
        month(order_date)
	order by
		year(order_date),
        month(order_date)
),

predicted_sales
as (
	select
		year,
        month,
        sales,
        avg(sales) over (
			order by
				year,
                month
			rows between 5 preceding and current row
        ) as predict_next_month_sale,
        lead(sales) over (
			order by
				year,
                month
        ) as real_next_month_sale
    from month_sales
)
select
	year,
    month,
    sales,
    predict_next_month_sale,
    real_next_month_sale
from predicted_sales

