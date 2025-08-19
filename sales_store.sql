create table sales_store (
transaction_id varchar(15),
customer_id varchar(15),
customer_name varchar(30),
customer_age int,
gender varchar(15),
product_id varchar(15),
product_name varchar(15),
product_category varchar(15),
quantity int,
prce float,
payment_mode varchar(15),
purchase_date date,
time_of_purchase time,
status varchar(15)

)
SELECT * FROM sales_store
SELECT * INTO sales from sales_store
SELECT * FROM sales
--Data cleaning
--For duplicates
--1.
SELECT transaction_id,COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id)>1
"TXN855235"
"TXN240646"
"TXN342128"
"TXN981773"

--2.
WITH cte AS(
SELECT ctid,
	ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS ROW_NUM
FROM sales
)
DELETE FROM sales
USING cte
WHERE sales.ctid=cte.ctid
AND cte.ROW_NUM>1
AND sales.transaction_id IN ('TXN855235','TXN240646','TXN342128','TXN981773');




SELECT * FROM cte
WHERE transaction_id IN ('TXN855235','TXN240646','TXN342128','TXN981773')


--2.correction of header
SELECT * FROM sales
ALTER TABLE sales RENAME COLUMN prce TO Price;
--ALTER TABLE sales RENAME COLUMN quantity TO Quantity;
-- check datatype

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='sales'

-- to check null values


/*DO $$
DECLARE
    col_list TEXT;
    sql_query TEXT;
BEGIN
    -- build condition for all columns
    SELECT string_agg(format('%I IS NULL', column_name), ' OR ')
    INTO col_list
    FROM information_schema.columns
    WHERE table_name = 'sales;

    -- build and run final query
    sql_query := format('SELECT * FROM sales WHERE %s;', col_list);
    EXECUTE sql_query;
END;
$$ language plpgsql;*/

--treating null values
SELECT *
FROM sales
WHERE transaction_id is NULL

OR customer_id IS NULL
OR customer_name IS NULL
OR transaction_id IS NULL
OR customer_age IS NULL
OR gender IS NULL
OR product_id IS NULL
OR product_name IS NULL
OR product_category IS NULL
OR quantity IS NULL
OR price IS NULL
OR purchase_date IS NULL

OR payment_mode IS NULL
OR time_of_purchase IS NULL
OR status IS NULL


DELETE FROM sales
WHERE transaction_id is NULL

SELECT * FROM sales
WHERE customer_name ='Ehsaan Ram'

UPDATE sales 
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM sales
WHERE customer_name ='Damini Raju'

UPDATE sales 
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'


SELECT * FROM sales
WHERE customer_id='CUST1003'

UPDATE sales
SET customer_name='Mahika Saini', customer_age='35',gender='Male'
WHERE customer_id='CUST1003'

---data cleaning

SELECT DISTINCT gender
FROM sales

UPDATE sales
SET gender='M'
WHERE gender='Male'

UPDATE sales
SET gender='F'
WHERE gender='Female'

SELECT DISTINCT payment_mode
FROM sales

UPDATE sales
SET payment_mode='Credit card'
WHERE payment_mode='CC' OR  payment_mode='Credit Card'


---------------------------
--1. What are the top 5 most selling products by quantity?
SELECT product_name ,SUM(quantity) AS total_quantity FROM sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 5
--BP: so that we will able to know which products are in demands and we can manage our stocks accordingly.

--2.Which products are most frequently cancelled?
SELECT product_name,COUNT(*) AS cancelled FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY cancelled DESC
LIMIT 5
--BP: frequently cancelled ,affect revenue and break customer trust. so that we can identify poor performing of the product.

--3.What time of the day has highest time of purchase?

SELECT 
CASE
WHEN EXTRACT(HOUR from time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
WHEN EXTRACT(HOUR from time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
WHEN EXTRACT(HOUR from time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
WHEN EXTRACT(HOUR from time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END AS time_of_day,
COUNT(*) AS total_orders

FROM sales
GROUP BY time_of_day
ORDER BY total_orders DESC
LIMIT 1


--BP: find peak sales time. so that we optimize our staff, promotions, and server loads.

--4.Who are the top 5 spending customer?
select customer_name,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_spend
from sales
group by customer_name
order by sum(price * quantity) desc
limit 5
--BP: Identify VIP Customer so that we can offer them loyality rewards and extra concern.

--5.Which product category generate the highest revenue?
SELECT product_category, 
--SUM(price*quantity) AS total_revenue
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_revenue
from sales
group by product_category
order by sum(price * quantity) desc
limit 1

--BP: Identify top performing category so that we can analyse high demand categories.

--6.What is the return /cancellation rate per product category?

SELECT 
    product_category,
    ROUND((COUNT(CASE WHEN status = 'cancelled' THEN 1 END)::decimal * 100.0 / COUNT(*)), 3) 
        || ' %' AS cancelled_percent,
	ROUND((COUNT(CASE WHEN status = 'returned' THEN 1 END)::decimal * 100.0 / COUNT(*)), 3) 
        || ' %' AS returned_percent	
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC,returned_percent DESC ;

--BP: Monitor dissatisfaction Trends per category and reduce returns improve product description or Expectations helps to identify and fixed product or logistics issues.

--7.What is the most preferred payment mode?
SELECT payment_mode, COUNT(*) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count DESC
LIMIT 1

--BP:It is easy to know which payment option customer prefer

--8.How does age group affect purchasing behaviour?


select case
when customer_age between 18 AND 30 then '18-30'
when customer_age between 31 and 45 then '31-45'
when customer_age between 46 and 60 then '46-60'
end as age_group,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_purchase 

from sales 
group by age_group
order by total_purchase 


--BP:Understand customer demographics and targeted marketing and product recommendation by the age group.

--9.What's total monthly sales trend?
SELECT 

TO_CHAR(purchase_date,'YYYY-MM') AS month_num,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_sales,

SUM(quantity) AS total_quantity
FROM sales

GROUP BY month_num
ORDER BY  month_num 

--BP: Sales fluctions go unnoticed to prevent that it helps to plan inventory and marketing according to seasonal trends.

--10.Are certain genders buying more specific product categories?

SELECT 
    product_category,
    COUNT(*) FILTER (WHERE gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE gender = 'F') AS female_count
FROM sales
GROUP BY product_category
ORDER BY product_category;

--BP:Gender based product preferences so that we can add personalized ads gender focused campaigns.

