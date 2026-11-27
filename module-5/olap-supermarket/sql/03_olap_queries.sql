-- OLAP queries on the supermarket data warehouse. Each query starts with a "-- name:" line so the notebook can
-- run them one by one. Sales are in the data's currency units, before the 5% tax.

-- name: slice_yangon
-- Slice: keep only the Yangon store and compare each category's share with its share in all stores.
SELECT category,
       round(sum(total_sales) FILTER (WHERE store_location = 'Yangon'), 2) AS yangon_sales,
       round(100 * sum(total_sales) FILTER (WHERE store_location = 'Yangon')
             / sum(sum(total_sales) FILTER (WHERE store_location = 'Yangon')) OVER (), 1) AS yangon_share_pct,
       round(sum(total_sales), 2) AS all_sales,
       round(100 * sum(total_sales) / sum(sum(total_sales)) OVER (), 1) AS all_share_pct
FROM v_sales
GROUP BY category
ORDER BY yangon_sales DESC;

-- name: slice_city_category
-- Slice by each store in turn: sales per category in every store.
SELECT store_location, category, round(sum(total_sales), 2) AS sales, sum(quantity) AS units
FROM v_sales
GROUP BY store_location, category
ORDER BY store_location, sales DESC;

-- name: dice
-- Dice: a smaller cube cut on three dimensions at once.
-- Two stores, two categories and e-wallet payments only, split by month.
SELECT store_location, category, month_name, count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
WHERE store_location IN ('Mandalay', 'Naypyitaw')
  AND category IN ('Food and beverages', 'Health and beauty')
  AND payment_method = 'Ewallet'
GROUP BY store_location, category, month, month_name
ORDER BY store_location, category, month;

-- name: drill_month
-- Drill-down level 1: monthly totals for each store.
SELECT store_location, month, month_name, count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY store_location, month, month_name
ORDER BY store_location, month;

-- name: drill_day
-- Drill-down level 2: daily totals for each store.
SELECT store_location, date_value, day_of_week, count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY store_location, date_value, day_of_week
ORDER BY store_location, date_value;

-- name: drill_hour
-- Drill-down level 3: sales for each hour of the day in each store (all days together).
SELECT store_location, hour, count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY store_location, hour
ORDER BY store_location, hour;

-- name: weekday
-- Sales by day of the week in each store, to find the busiest days.
SELECT store_location, extract(isodow FROM date_value)::int AS dow, day_of_week,
       count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY store_location, dow, day_of_week
ORDER BY store_location, dow;

-- name: rollup
-- Roll-up: daily sales summed to months, to the quarter and to a grand total in one query.
-- Rows where month is NULL are the quarter totals. The row where quarter is also NULL is the grand total.
SELECT year, quarter, month, round(sum(total_sales), 2) AS sales, count(*) AS invoices
FROM v_sales
GROUP BY ROLLUP (year, quarter, month)
ORDER BY year, quarter, month;

-- name: rollup_week
-- Roll-up from days to weeks, to see the week by week pattern.
SELECT week_of_year, min(date_value) AS first_day, max(date_value) AS last_day,
       count(DISTINCT date_value) AS days, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY week_of_year
ORDER BY week_of_year;

-- name: pivot_store_month
-- Pivot view 1: stores as rows and months as columns.
SELECT store_location,
       round(sum(total_sales) FILTER (WHERE month = 1), 2) AS january,
       round(sum(total_sales) FILTER (WHERE month = 2), 2) AS february,
       round(sum(total_sales) FILTER (WHERE month = 3), 2) AS march,
       round(sum(total_sales), 2) AS total
FROM v_sales
GROUP BY store_location
ORDER BY store_location;

-- name: pivot_category_month
-- Pivot view 2: the same measure turned so that product categories are the rows.
SELECT category,
       round(sum(total_sales) FILTER (WHERE month = 1), 2) AS january,
       round(sum(total_sales) FILTER (WHERE month = 2), 2) AS february,
       round(sum(total_sales) FILTER (WHERE month = 3), 2) AS march,
       round(sum(total_sales), 2) AS total
FROM v_sales
GROUP BY category
ORDER BY total DESC;

-- name: cube
-- The full cube of store by category: every combination plus all subtotals and the grand total.
SELECT coalesce(store_location, 'All stores') AS store_location,
       coalesce(category, 'All categories') AS category,
       round(sum(total_sales), 2) AS sales,
       GROUPING(store_location, category) AS level
FROM v_sales
GROUP BY CUBE (store_location, category)
ORDER BY level, store_location, category;

-- name: payment_store
-- Payment methods in each store.
SELECT store_location, payment_method, count(*) AS invoices, round(sum(total_sales), 2) AS sales
FROM v_sales
GROUP BY store_location, payment_method
ORDER BY store_location, payment_method;
