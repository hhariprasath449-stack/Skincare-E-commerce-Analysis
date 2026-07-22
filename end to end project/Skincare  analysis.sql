create database skincare_data;
use skincare_data;

create table orders (
order_id varchar(50),
customer_id varchar(50),
order_date date,
order_status varchar(50), 
payment_method varchar(50),
sales_channel varchar(50),
gross_amount decimal(10,2),
discount_amount decimal(10,2),
shipping_fee int,
final_amount decimal(10,2), 
delivered_date date);


-- overall business performance
select count(distinct customer_id) as total_customers, count(order_id) as total_orders,
round(sum(final_amount),2) as total_revenue,round(avg(final_amount),2) as total_order_value from orders;

-- monthly sales trend
with monthly_sales_trend as(
select month (order_date) as monthly, sum(final_amount) as revenue from orders
group by month(order_date)
)
select monthly,revenue,
lag(revenue) over(order by revenue desc) as prev_revenue,
round(revenue - lag(revenue) over(order by revenue desc)*100/lag(revenue) over(order by revenue desc),2) as growth_pct from monthly_sales_trend;


-- top 5 products
select p.product_name,p.category,sum(oi.item_total) as revenue from order_items oi
inner join products p 
on p.product_id = oi.product_id
group by p.product_name,p.category
order by revenue desc
limit 5;

-- customer  segmentation
select customer_name,total_spents,total_orders,
case
when total_spents>10000 then 'VIP'
when total_spents>5000 then 'premium'
when total_orders = 1 then 'regular'
else 'occasional'
end as segment from(
select c.customer_name,sum(o.final_amount) as total_spents,count(o.order_id) as total_orders from orders o 
inner join customers c 
on c.customer_id = o.customer_id
group by c.customer_name) r 
order by total_spents desc;


-- return rate analysis
select p.category,rt.return_reason, count(distinct oi.order_id) as total_orders,count(distinct rt.return_id) as total_returns,
round(count(distinct rt.return_id)*100/count(distinct oi.order_id),2) as return_rate from products p 
inner join order_items oi
on p.product_id = oi.product_id
left join returns rt 
on rt.product_id = p.product_id
group by p.category,rt.return_reason
order by return_rate desc;

-- revenue by sales channel
select sales_channel,count(order_id) as total_orders,
sum(final_amount) as revenue, avg(final_amount) as avg_revenue from orders
group by sales_channel
order by revenue desc;

-- customer acquisition analysis
select c.acquisition_channel, count(distinct c.customer_id) as total_customers,sum(o.final_amount) as total_revenue,
round(sum(o.final_amount)/ count(distinct c.customer_id),2) as revenue_per_customer from customers c 
inner join orders o 
on o.customer_id = c.customer_id
group by c.acquisition_channel
order by total_revenue desc;


-- product rating vs sales
select p.product_name,sum(oi.quantity) as units_sold,avg(r.rating) as avg_rating ,
case
when avg(r.rating)>=4 and sum(oi.quantity) >=100 then 'star product'
when avg(r.rating)<3 and sum(oi.quantity) >=100 then 'high sales poor rating'
when avg(r.rating)>=4 and sum(oi.quantity) < 100 then 'hidden gem'
else 'needs improvements'
end as products_segement from products p 
inner join order_items oi 
on oi.product_id = p.product_id
inner join reviews r 
on r.product_id = p.product_id
group by p.product_name
order by avg_rating desc;

-- repeat customers analysis
with customer_orders as(
select c.customer_name,count(o.order_id) as total_orders,sum(o.final_amount) as total_spents,min(o.order_date) as first_order,max(o.order_date) as last_order
from customers c 
inner join orders o 
on o.customer_id = c.customer_id
group by c.customer_name
) select customer_name,total_orders,total_spents,first_order,last_order from customer_orders
where total_orders>1
order by total_orders desc;


-- customer_lifetime_value
select c.customer_name,c.acquisition_channel,c.city,sum(o.final_amount) as life_time_value,count(o.order_id) as total_orders,
avg(o.final_amount) as avg_orders,
case
when sum(o.final_amount)>10000 then 'VIP'
when sum(o.final_amount)>4000 then 'regular'
else 'new' end as segment from customers c 
inner join orders o 
on o.customer_id = c.customer_id
group by c.customer_name,c.acquisition_channel,c.city
order by life_time_value desc;

-- avg days between orders & delivery
select round(avg(datediff(delivered_date,order_date)),1) as days_between ,
min(datediff(delivered_date,order_date)) as faster_delivery,
max(datediff(delivered_date,order_date)) as slowest_delivery ,
count(case 
when datediff(delivered_date,order_date)<=3 then 1 end) as delivery_within_3days ,
count(case
when datediff(delivered_date,order_date) between 4 and 7 then 1 end) as delivered_4_to_7_days,
count(case when datediff(delivered_date,order_date)>7 then 1 end) as delivered_after_7 from orders
where delivered_date is not null
and order_status='delivered';

-- late delivered
select order_id,order_date,delivered_date,
datediff(delivered_date,order_date) as days_to_deliver,
case 
when datediff(delivered_date,order_date)<3 then 'fast'
when datediff(delivered_date,order_date)<7 then 'normal'
else 'late' end as delivery_status from orders
where delivered_date is not null and order_status='delivered'
order by days_to_deliver desc;





















