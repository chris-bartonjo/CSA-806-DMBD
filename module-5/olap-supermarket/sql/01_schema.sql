-- Star schema for the supermarket sales data warehouse (PostgreSQL).
-- Follows the "Practical Activity on OLAP" in the CSA 806 Module 5 notes. PostgreSQL folds names to lower case,
-- so snake_case names are used (DateKey becomes date_key) and SERIAL replaces MySQL's AUTO_INCREMENT.
-- dim_time is added so that sales can be drilled down to the hour. dim_product has no brand column because the
-- data has no brand.

DROP TABLE IF EXISTS fact_sales, dim_date, dim_time, dim_store, dim_product, dim_payment, stg_sales CASCADE;

-- Staging table: the CSV is loaded here unchanged (extract step).
CREATE TABLE stg_sales (
    invoice_id        TEXT,
    branch            TEXT,
    city              TEXT,
    customer_type     TEXT,
    gender            TEXT,
    product_line      TEXT,
    unit_price        NUMERIC(10,2),
    quantity          INT,
    tax_5pct          NUMERIC(12,4),
    total             NUMERIC(12,4),
    sale_date         TEXT,             -- M/D/YYYY in the CSV
    sale_time         TEXT,             -- HH:MM in the CSV
    payment           TEXT,
    cogs              NUMERIC(12,2),
    gross_margin_pct  NUMERIC(12,9),
    gross_income      NUMERIC(12,4),
    rating            NUMERIC(3,1)
);

CREATE TABLE dim_date (
    date_key     INT PRIMARY KEY,        -- YYYYMMDD
    date_value   DATE NOT NULL,
    year         INT,
    quarter      INT,
    month        INT,
    month_name   TEXT,
    day          INT,
    day_of_week  TEXT,
    week_of_year INT
);

CREATE TABLE dim_time (
    time_key  INT PRIMARY KEY,           -- hour of the day, 0 to 23
    hour      INT,
    day_part  TEXT                       -- Morning, Afternoon or Evening
);

CREATE TABLE dim_store (
    store_id       INT PRIMARY KEY,
    branch_code    TEXT,
    store_location TEXT,
    region         TEXT
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    category   TEXT
);

CREATE TABLE dim_payment (
    payment_method_id   INT PRIMARY KEY,
    payment_method_type TEXT
);

CREATE TABLE fact_sales (
    sales_id          SERIAL PRIMARY KEY,
    invoice_id        TEXT UNIQUE,       -- kept so each row can be traced back to the source
    date_key          INT REFERENCES dim_date (date_key),
    time_key          INT REFERENCES dim_time (time_key),
    store_id          INT REFERENCES dim_store (store_id),
    product_id        INT REFERENCES dim_product (product_id),
    payment_method_id INT REFERENCES dim_payment (payment_method_id),
    quantity          INT,
    unit_price        NUMERIC(10,2),
    total_sales       NUMERIC(12,2),     -- unit_price * quantity, before the 5% tax
    tax_amount        NUMERIC(12,4)
);
