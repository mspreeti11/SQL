show databases;
use gdb023;

/*QUERY 1*/
/**1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.**/

select *
from gdb023.dim_customer
where customer="Atliq Exclusive" and region="APAC";

/*QUERY 2*/
/**What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields, unique_products_2020     unique_products_2021     percentage_chg**/


WITH CTE1 AS 
( SELECT COUNT(DISTINCT product_code) as unique_product_2020
from gdb023.fact_sales_monthly 
where fiscal_year = "2020"
group by fiscal_year),
CTE2 AS ( SELECT COUNT(DISTINCT product_code) as unique_product_2021 
from gdb023.fact_sales_monthly 
where fiscal_year = "2021"
group by fiscal_year)
SELECT * , 100.00*(unique_product_2021-unique_product_2020)/unique_product_2020 as percentage_chng
from CTE1
JOIN CTE2;

/*QUERY 3*/
/**Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields,  segment   product_count**/


select segment, count(distinct product_code) as product_count
FROM dim_product
group by segment
order by product_count DESC;

/*QUERY 4*/
/**Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment product_count_2020    product_count_2021    difference**/ 


WITH CTE41 AS 
( SELECT segment, COUNT(DISTINCT dp.product_code) AS product_count_2020
FROM dim_product dp
JOIN gdb023.fact_sales_monthly fsm
ON  dp.product_code = fsm.product_code
WHERE fiscal_year = "2020"
GROUP BY segment),
CTE42 AS (SELECT segment, COUNT(DISTINCT dp.product_code) AS product_count_2021 
FROM dim_product dp
JOIN gdb023.fact_sales_monthly fsm
ON  dp.product_code = fsm.product_code
WHERE fiscal_year = "2021"
GROUP BY segment)
SELECT *, (product_count_2021-product_count_2020) as difference
FROM CTE41 JOIN CTE42 
USING (Segment)
ORDER BY difference DESC; 

/*QUERY 5*/
/**Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code    product     manufacturing_cost**/

(SELECT dp.product_code, product, manufacturing_cost
FROM fact_manufacturing_cost fmc
join dim_product dp
ON dp.product_code = fmc.product_code
group by product_code
ORDER BY manufacturing_cost DESC
Limit 1)
UNION
(SELECT dp.product_code, product, manufacturing_cost
FROM fact_manufacturing_cost fmc
join dim_product dp
ON dp.product_code = fmc.product_code
group by product_code
ORDER BY manufacturing_cost ASC
Limit 1); 

/*QUERY 6*/
/**Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 
2021 and in the Indian market. The final output contains these fields, customer_code    customer    average_discount_percentage**/

SELECT customer_code, customer, Round(avg(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer dm
JOIN fact_pre_invoice_deductions
USING (customer_code)
where fiscal_year = "2021" and market = "India"
group by customer_code
order by average_discount_percentage DESC
limit 5; 

/*QUERY 7*/
/**Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get 
an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year
Gross sales Amount**/

SELECT monthname(date)as Month, year(date) as Year, sum(sold_quantity*gross_price) AS gross_sales_amount
from fact_sales_monthly fsm
join dim_customer dc
USING (customer_code)
join fact_gross_price
USING (product_code)
where customer = "Atliq Exclusive"
group by 1,2;


/*QUERY 8*/
/**In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter   total_sold_quantity**/

select Quarter(date) as Q1, sum(sold_quantity) as Quantity_Sold
from fact_sales_monthly
where year(date) = '2020'
group by Q1
ORDER BY Quantity_Sold ASC;

/*QUERY 9*/
/**Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output 
contains these fields,  channel  gross_sales_mln   percentage**/


WITH CTE91 AS (select channel, (SUM(sold_quantity*gross_price)/1000000)AS Gross_Sales_MLN
from fact_sales_monthly fsm
join fact_gross_price
USING (product_code)
join dim_customer
using (customer_code)
where fsm.fiscal_year = '2021'
group by 1)
select channel, Gross_Sales_MLN, round(100*Gross_Sales_MLN/Total_sales,2) as Percentage
from CTE91
CROSS JOIN (select sum(Gross_Sales_MLN)AS Total_sales from CTE91) as t;

/*QUERY 10*/
/**Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains 
these fields, division   product_code  product   total_sold_quantity  rank_order**/

with CTE10 AS (SELECT division, product_code, product, sum(sold_quantity) AS total_sold_quantity, 
		rank() OVER(partition by division order by sold_quantity) AS rank_order

from fact_sales_monthly fsm
join dim_product dpah
USING (product_code)
where fiscal_year = '2021'
group by 1,2,3)
Select * from CTE10
where rank_order <= 3;
