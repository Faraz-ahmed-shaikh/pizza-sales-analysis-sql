-- 1. Total number of orders placed
select count(order_id) as total_orders_placed
from orders;

-- 2. Total revenue generated from pizza sales
select sum(od.quantity * p.price) as total_revenue
from order_details od
inner join pizzas p on od.pizza_id = p.pizza_id;


-- 3. Most expensive pizza (name and price)
select pt.name, p.price
from pizzas p
inner join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
order by p.price desc
limit 1;


-- 4. Distribution of orders by pizza size
select count(od.order_details_id) as total_orders, p.size
from order_details od
inner join pizzas p on od.pizza_id = p.pizza_id
group by p.size
order by total_orders desc;


-- 5. Top 5 most ordered pizzas by total quantity sold
select pt.name, sum(od.quantity) as total_quantity
from order_details od
inner join pizzas p on od.pizza_id = p.pizza_id
inner join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.name
order by total_quantity desc
limit 5;


-- 6. Total quantity sold by pizza category
select pt.category, sum(od.quantity) as total_quantity
from order_details od
inner join pizzas p on od.pizza_id = p.pizza_id
inner join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.category
order by total_quantity desc;


-- 7. Order distribution by hour of the day
alter table orders
alter column time type time using time::time;

select extract(hour from time) as hour,
       count(order_id) as orders_placed
from orders
group by hour
order by hour;


-- 8. Number of pizza types in each category
select pt.category,
       count(pt.name) as total_pizza_types
from pizza_types pt
group by pt.category;


-- 9. Average number of pizzas ordered per day
select round(avg(ordered_pizzas), 0) as avg_pizza_per_day
from (
    select o.date, sum(od.quantity) as ordered_pizzas
    from orders o
    inner join order_details od on o.order_id = od.order_id
    group by o.date
) as daily_orders;


-- 10. Top 3 pizzas by total revenue
select pt.name,
       sum(od.quantity * p.price) as revenue
from pizza_types pt
inner join pizzas p on p.pizza_type_id = pt.pizza_type_id
inner join order_details od on od.pizza_id = p.pizza_id
group by pt.name
order by revenue desc
limit 3;


-- 11. Percentage revenue contribution by pizza category
with revenue_by_category as (
    select pt.category,
           sum(od.quantity * p.price) as revenue
    from pizza_types pt
    inner join pizzas p on p.pizza_type_id = pt.pizza_type_id
    inner join order_details od on od.pizza_id = p.pizza_id
    group by pt.category
)
select category,
       100 * revenue / sum(revenue) over () as percentage_contribution
from revenue_by_category
order by percentage_contribution desc;


-- 12. Cumulative revenue over time
with revenue_by_date as (
    select o.date,
           sum(od.quantity * p.price) as revenue
    from orders o
    inner join order_details od on o.order_id = od.order_id
    inner join pizzas p on p.pizza_id = od.pizza_id
    inner join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
    group by o.date
    order by o.date
)
select date,
       revenue,
       sum(revenue) over (rows between unbounded preceding and current row) as cumulative_revenue
from revenue_by_date;


-- 13. Top 3 pizza types by revenue within each category
select *
from (
    select category,
           pizza_type,
           revenue,
           rank() over (partition by category order by revenue desc) as rank
    from (
        select pt.category as category,
               pt.name as pizza_type,
               sum(od.quantity * p.price) as revenue
        from pizzas p
        inner join order_details od on p.pizza_id = od.pizza_id
        inner join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
        group by pt.category, pt.name
    ) as category_revenue
) as ranked_pizzas
where rank <= 3;
