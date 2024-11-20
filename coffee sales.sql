create database coffee_sales;
use coffee_sales;
select * from sales;
/* 1. **Coffee Consumers Count**  
   How many people in each city are estimated to consume coffee,
   given that 25% of the population does? */
   
   select city_name,
   round(population *0.25) as cofee_consumers
   from city
   order by 2 desc;
   
/* 2. **Total Revenue from Coffee Sales**  
   What is the total revenue generated from coffee sales
   across all cities in the last quarter of 2023?*/
   
   select sum(total)
   from sales
   where 
   year(sale_date) = 2023 and
   quarter(sale_date) = 4;

-- city wise sales
  select 
  c.city_name,
  sum(s.total) as revenue
   from sales s
   join customers cs
   on s.customer_id = cs.customer_id
   join city c
   on c.city_id = cs.city_id
   where 
   year(s.sale_date) = 2023 and
   quarter(s.sale_date) = 4
   group by 1
   order by 2 desc;

/* 3. **Sales Count for Each Product**  
   How many units of each coffee product have been sold? */
   
   select p.product_name , count(sale_id)
   from sales s
   left join products p
   on s.product_id = p.product_id
   group by p.product_name
   order by 2 desc;

/* 4. **Average Sales Amount per City**  
   What is the average sales amount per customer in each city? */
   
   select c.city_name,
   round(sum(s.total)/count(distinct s.customer_id),2) avg_sales_amt
   from sales s
   left join customers cs
   on s.customer_id = cs.customer_id
   left join city c
   on c.city_id = cs.city_id
   group by c.city_name
   order by 2 desc;

 

/* 5.  **City Population and Coffee Consumers**  
   Provide a list of cities along with their populations 
   and estimated coffee consumers.*/
   
   select city_name,
   population as city_population,
   round(population *0.25) as estimated_cofee_consumers
   from city;


/* 6. **Top Selling Products by City**  
   What are the top 3 selling products in 
   each city based on sales volume?*/

select * from 
(select
c.city_name,
p.product_name,
count(s.sale_id) as num_of_sales,
dense_rank() 
over (partition by c.city_name order by count(s.sale_id)desc) selling_rank
from sales s
join products p
on s.product_id = p.product_id
join customers cs
on s.customer_id = cs.customer_id
join city c
on c.city_id = cs.city_id
group by 1,2
order by 1,selling_rank )
as t1
where selling_rank <= 3;


/* 7. **Customer Segmentation by City**  
   How many unique customers are there in each
   city who have purchased coffee products? */

   select c.city_name,
   count(distinct s.customer_id)
   from sales s
  join customers cs
   on s.customer_id = cs.customer_id
   join city c
   on c.city_id = cs.city_id
   where 
	s.product_id between 1 and 14
   group by c.city_name;


/* 8. **Average Sale vs Rent**  
   Find each city and their average sale 
   per customer and avg rent per customer */
 
with sales_cus_city_t
as
(select 
s.sale_id,
s.customer_id,
s.total,
cs.city_id,
c.city_name,
c.estimated_rent
from sales s
join customers cs
on s.customer_id = cs.customer_id
join city c
on c.city_id = cs.city_id)
select city_name city,
max(estimated_rent) rent,
count(distinct customer_id) total_customers,
round(sum(total) / count( customer_id)) avg_sales_per_customer,
round(max(estimated_rent) / count( customer_id)) avg_rent_customer
from sales_cus_city_t
group by 1
order by 4 desc;
 
   
	
/* 9. **Monthly Sales Growth**  
   Sales growth rate: Calculate the percentage growth 
   (or decline) in sales over different time periods (monthly). */
   
select 
c.city_name,
month(s.sale_date) as s_month,
year(s.sale_date) as s_year,
SUM(s.total) as cr_month_sale,
lag(sum(s.total),1) over 
(partition by c.city_name 
order by year(s.sale_date),month(s.sale_date)) as prev_month_sale,
round(((SUM(s.total))-(lag(sum(s.total),1) over 
(partition by c.city_name 
order by year(s.sale_date),month(s.sale_date))))/(lag(sum(s.total),1) over 
(partition by c.city_name 
order by year(s.sale_date),month(s.sale_date))) *100 ,2) as growth_rate_percentage
from sales s
join customers cs
on s.customer_id = cs.customer_id
join city c
on c.city_id = cs.city_id
group by 1,3,2;
 

/*10. **Market Potential Analysis**  
    Identify top 3 city based on highest sales, 
    return city name, total sale, total rent, 
    total customers, estimated  coffee consumer */
 
select 
c.city_name city,
count(s.sale_id) as num_of_sales,
sum(s.total) as total_sales,
max(c.estimated_rent) total_rent,
count(distinct s.customer_id) total_customers,
round(max(c.population*0.25 )) estimated_coffee_consumer
from sales s
join customers cs
on s.customer_id = cs.customer_id
join city c
on c.city_id = cs.city_id
group by c.city_name
order by 2 desc
limit 3 ;

## 11. Top 3 products sales trend quarter wise

with top3_selling_prod  as 
(
select
s.product_id,
p.product_name,
sum(s.total) as total_sales,
dense_rank () over ( order by sum(s.total) desc) as prod_rank
from sales s
join products p
on s.product_id = p.product_id
group by 1,2
order by 4
limit 3
) 
select tp.product_name,
year(s.sale_date) year_of_sales,
quarter(s.sale_date) q_of_sale,
sum(s.total) total_sale,
lag(sum(s.total),1) over 
(order by year(s.sale_date),quarter(s.sale_date)) as pq_sale,
sum(s.total) - lag(sum(s.total),1) over 
(order by year(s.sale_date),quarter(s.sale_date)) as sales_growth
from sales s
join top3_selling_prod tp
on tp.product_id = s.product_id
group by 1,2,3
order by 1
;