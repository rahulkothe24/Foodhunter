use foodhunter ;

select * from orders;

select order_id , delivered_time , final_price , order_rating from orders limit 20000 ;

select count(order_id) from orders ;

select count(distinct order_id) from orders ;
select count(distinct driver_id) from orders ;

select * from orders;

SELECT COUNT(customer_id) FROM customers ;

SELECT  COUNT(DISTINCT  item_id) FROM food_items;

SELECT first_name, last_name, address FROM customers;

SELECT COUNT(*) FROM customers;
SELECT COUNT(DISTINCT item_id) FROM food_items;
SELECT COUNT(customer_id) FROM orders ;


-- month wise sales ---2022-06-01 00:00:00. to. 2022-09-29 00:00:00 
select max(order_date) from orders ;

select COUNT(order_id) from orders
Where  order_date>= '2022-06-01' AND order_date<= '2022-09-30';


SELECT COUNT(order_id) 
FROM orders
WHERE order_date >= '2022-06-01' AND order_date <= '2022-09-30';

--- between ---
select COUNT(order_id) from orders
Where  order_date between '2022-06-01' AND  '2022-09-30';


select count(order_id) from orders
where customer_id = 2 ;

--- Analysign the treds in sales ---
select order_date , COUNT(order_id) as OrderQuantity from orders group by order_date ;

-- get the month from the date --

select month(order_date) , COUNT(order_id) as OrderQuantity from orders group by month(order_date) ;



-- Sales Impact as per weekday--

select dayofweek(order_date) as Wday , sum(final_price) as Total_Revenue , count(order_id) as Order_Count
from orders
group by Wday
Order by Wday ;


-- WEEKday VS Weekend using CASE --

select  sum(final_price) as Total_Revenue , count(order_id) as Order_Count,
case
when dayofweek(order_date)=1 then "weekend"
when dayofweek(order_date)=7 then "weekend"
else "weekday"
end as Wday
from orders
group by Wday ;


-- discount Impact on Sales --

select month(order_date) as month , sum(final_price) as TotalRevenue,
sum(discount)/sum(final_price) as Discount_Sales_Ratio,
sum(discount) as Total_Discount,
count(order_id) as Order_Count
from orders
group by month order by month ;

-- discount rate is same there is no variation so it is not the reason for dropping sales 

select  sum(final_price) as Total_Revenue , count(order_id) as Order_Count,
case
when dayofweek(order_date) BETWEEN 2 AND 6 then "weekday"
when dayofweek(order_date) IN (1,7) then "weekend"
end as day_of_week,
Month(order_date) as Month ,
Round(sum(final_price),0) AS total_revenue
FROM orders
GROUP BY Day_of_week , Month
ORDER BY Day_of_week ;



-- percentage change from Previous Revenue --


select *,
      round(((total_revenue-previous_rev)/previous_rev)*100) as percentage_change
       from
       (
         select * ,
         LAG(total_revenue) OVER (partition by Day_of_week) as previous_rev
         from
	   (
	    select
	     CASE
           when dayofweek(order_date) BETWEEN 2 AND 6 then "weekday"
           when dayofweek(order_date) IN (1,7) then "weekend"
          end as day_of_week,
          Month(order_date) as Month ,
          Round(sum(final_price),0) AS total_revenue
	     FROM orders
         GROUP BY Day_of_week , Month
         ORDER BY Day_of_week)
         t1
             )
	  t2;
-- we have to work on the weekday sales 


SELECT *,
      ROUND(((total_revenue - previous_rev) / previous_rev) * 100, 2) AS percentage_change
FROM (
      SELECT *, 
             LAG(total_revenue) OVER (PARTITION BY day_of_week ORDER BY Month) AS previous_rev
      FROM (
            SELECT 
                   CASE 
                     WHEN DAYOFWEEK(order_date) = 1 THEN 'Sunday'
                     WHEN DAYOFWEEK(order_date) = 2 THEN 'Monday'
                     WHEN DAYOFWEEK(order_date) = 3 THEN 'Tuesday'
                     WHEN DAYOFWEEK(order_date) = 4 THEN 'Wednesday'
                     WHEN DAYOFWEEK(order_date) = 5 THEN 'Thursday'
                     WHEN DAYOFWEEK(order_date) = 6 THEN 'Friday'
                     WHEN DAYOFWEEK(order_date) = 7 THEN 'Saturday'
                   END AS day_of_week,
                   MONTH(order_date) AS Month,
                   ROUND(SUM(final_price), 0) AS total_revenue
            FROM orders
            GROUP BY day_of_week, Month
            ORDER BY day_of_week, Month
           ) t1
      ) t2;


-- Insight Based on Deliveru time --

select Month(order_date) AS Month ,
AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)) AS average_delivery_time
FROM orders
GROUP BY Month ;

-- increase in average delivery time --



-- dleivery parteners with avg_time --
select * from 
( 
select month, driver_id, avg_time , RANK() OVER(PARTITION BY month ORDER BY avg_time desc) AS driver_rank
FROM (
SELECT MONTH(order_date) AS month, driver_id, AVG(minute(TIMEDIFF(delivered_time, order_time))) AS avg_time
     FROM orders
     GROUP BY month,driver_id
) AS query_1
) query_2
where driver_rank between 1 and 5 ;



-- AS per food timing Meal of the Day --


SELECT 
    SUM(final_price) AS Total_Revenue, 
    COUNT(order_id) AS Order_Count,
    CASE
        WHEN order_time BETWEEN '06:00:00' AND '11:59:59' THEN 'Breakfast'
        WHEN order_time BETWEEN '12:00:00' AND '17:59:59' THEN 'Lunch'
        WHEN order_time BETWEEN '18:00:00' AND '23:59:59' THEN 'Brunch'
        WHEN order_time BETWEEN '00:00:00' AND '05:59:59' THEN 'Dinner'
    END AS Meal_of_day,
    MONTH(order_date) AS Month,
    ROUND(SUM(final_price), 0) AS total_revenue
FROM 
    orders
GROUP BY 
    Meal_of_day, Month
ORDER BY 
   Meal_of_day ;







-- food items order quantity --

select fi.food_type, SUM(oi.quantity) AS items_quantity
FROM orders_items oi
LEFT JOIN food_items fi ON oi.item_id = fi.item_id
GROUP BY fi.food_type ;


SELECT t2.food_type_new , SUM(t1.quantity) AS item_quantity
FROM orders_items t1
LEFT JOIN (
     SELECT item_id ,
        CASE
            WHEN food_type LIKE 'veg%' THEN 'veg'
            ELSE 'non-veg'
	    END AS food_type_new 
     FROM food_items
)t2 ON t1.item_id = t2.item_id
GROUP BY t2.food_type_new;


-- percentage change in segment --

SELECT
order_month,
time_segment,
total_revenue,
((total_revenue-(lag(total_revenue) over(partition by order_month)))/(lag(total_revenue) over(partition by order_month)))*100 as "percent_change"
from
(
SELECT
MONTH(order_date) AS order_month,
CASE
WHEN HOUR(order_time) BETWEEN 6 AND 11 THEN '6AM-12PM'
WHEN HOUR(order_time) BETWEEN 12 AND 17 THEN '12PM-6PM'
WHEN HOUR(order_time) BETWEEN 18 AND 23 THEN '6PM-12AM'
ELSE '12AM-6AM'
END AS time_segment,
SUM(final_price) AS total_revenue
FROM orders
GROUP BY order_month, time_segment
ORDER BY order_month, total_revenue DESC)
t1;


-- number of orders of each restaurent --

select r.restaurant_name, r.restaurant_id, r.cuisine, SUM(quantity) as item_quantity
FROM restaurants r
LEFT JOIN food_items fi ON r.restaurant_id = fi.restaurant_id
LEFT JOIN orders_items o ON fi.item_id = o.item_id
GROUP BY r.restaurant_id
ORDER BY item_quantity;


-- restaurant with no sales --

select r.restaurant_name, r.restaurant_id, r.cuisine, SUM(quantity) as item_quantity
FROM restaurants r
LEFT JOIN food_items fi ON r.restaurant_id = fi.restaurant_id
LEFT JOIN orders_items o ON fi.item_id = o.item_id
GROUP BY r.restaurant_id
HAVING item_quantity is NULL
ORDER BY item_quantity;

