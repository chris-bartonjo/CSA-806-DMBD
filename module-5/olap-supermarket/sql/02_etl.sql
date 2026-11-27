-- Transform and load. Run after the CSV has been copied into stg_sales.
-- Dimension tables are filled first, then the fact table looks up each key.

-- Clean: trim spaces and drop rows that repeat an invoice (the check in the notebook finds none).
UPDATE stg_sales SET invoice_id = trim(invoice_id), branch = trim(branch), city = trim(city),
                     product_line = trim(product_line), payment = trim(payment);
DELETE FROM stg_sales a USING stg_sales b
 WHERE a.ctid > b.ctid AND a.invoice_id = b.invoice_id;

-- dim_date: split each date into year, quarter, month, day and weekday.
INSERT INTO dim_date
SELECT DISTINCT
       to_char(d, 'YYYYMMDD')::int,
       d,
       extract(year FROM d)::int,
       extract(quarter FROM d)::int,
       extract(month FROM d)::int,
       trim(to_char(d, 'Month')),
       extract(day FROM d)::int,
       trim(to_char(d, 'Day')),
       extract(week FROM d)::int
FROM (SELECT to_date(sale_date, 'MM/DD/YYYY') AS d FROM stg_sales) s;

-- dim_time: one row for every hour of the day.
INSERT INTO dim_time
SELECT h, h, CASE WHEN h < 12 THEN 'Morning' WHEN h < 17 THEN 'Afternoon' ELSE 'Evening' END
FROM generate_series(0, 23) AS h;

-- dim_store: one row per branch with its city and region.
INSERT INTO dim_store
SELECT row_number() OVER (ORDER BY branch), branch, city,
       CASE city WHEN 'Yangon' THEN 'Yangon Region'
                 WHEN 'Mandalay' THEN 'Mandalay Region'
                 WHEN 'Naypyitaw' THEN 'Naypyidaw Union Territory' END
FROM (SELECT DISTINCT branch, city FROM stg_sales) s;

-- dim_product: one row per product line.
INSERT INTO dim_product
SELECT row_number() OVER (ORDER BY product_line), product_line
FROM (SELECT DISTINCT product_line FROM stg_sales) s;

-- dim_payment: one row per payment method.
INSERT INTO dim_payment
SELECT row_number() OVER (ORDER BY payment), payment
FROM (SELECT DISTINCT payment FROM stg_sales) s;

-- fact_sales: map each staging row to its dimension keys.
INSERT INTO fact_sales (invoice_id, date_key, time_key, store_id, product_id, payment_method_id,
                        quantity, unit_price, total_sales, tax_amount)
SELECT s.invoice_id,
       to_char(to_date(s.sale_date, 'MM/DD/YYYY'), 'YYYYMMDD')::int,
       split_part(s.sale_time, ':', 1)::int,
       st.store_id, p.product_id, pm.payment_method_id,
       s.quantity, s.unit_price,
       round(s.unit_price * s.quantity, 2),
       s.tax_5pct
FROM stg_sales s
JOIN dim_store   st ON st.branch_code = s.branch
JOIN dim_product p  ON p.category = s.product_line
JOIN dim_payment pm ON pm.payment_method_type = s.payment;

-- A view that joins the fact table to every dimension. The OLAP queries read from it.
CREATE OR REPLACE VIEW v_sales AS
SELECT f.sales_id, f.invoice_id, d.date_value, d.year, d.quarter, d.month, d.month_name, d.day, d.day_of_week,
       d.week_of_year, t.hour, t.day_part, st.branch_code, st.store_location, st.region, p.category,
       pm.payment_method_type AS payment_method, f.quantity, f.unit_price, f.total_sales, f.tax_amount
FROM fact_sales f
JOIN dim_date d     ON d.date_key = f.date_key
JOIN dim_time t     ON t.time_key = f.time_key
JOIN dim_store st   ON st.store_id = f.store_id
JOIN dim_product p  ON p.product_id = f.product_id
JOIN dim_payment pm ON pm.payment_method_id = f.payment_method_id;
