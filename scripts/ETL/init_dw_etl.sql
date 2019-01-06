USE dw_sales;

--SemanticException Cartesian products are disabled for safety reasons. If you know what you are doing, 
--please sethive.strict.checks.cartesian.product to false and that hive.mapred.mode is not set to 'strict' to proceed. 
--Note that if you may get errors or incorrect results if you make a mistake while using some of the unsafe features.
set hive.strict.checks.cartesian.product=false;
set hive.mapred.mode=nonstrict;
--In order to change the average load for a reducer (in bytes):
set hive.exec.reducers.bytes.per.reducer=65535000;
--In order to limit the maximum number of reducers:
set hive.exec.reducers.max=6;
--In order to set a constant number of reducers:
set mapreduce.job.reduces=2;

-- 清空表
TRUNCATE TABLE dw_sales.dim_customer;
TRUNCATE TABLE dw_sales.dim_product;
TRUNCATE TABLE dw_sales.dim_order;
TRUNCATE TABLE dw_sales.fact_sales_order;

-- 装载客户维度表
INSERT INTO dw_sales.dim_customer (customer_sk,customer_number,customer_name,customer_street_address,customer_zip_code,customer_city,customer_state,`version`,effective_date,expiry_date)
SELECT
    row_number() over (ORDER BY t1.customer_number) + t2.sk_max,
    t1.customer_number, 
    t1.customer_name, 
    t1.customer_street_address,
    t1.customer_zip_code, 
    t1.customer_city, 
    t1.customer_state, 
    1,
    '2019-01-03', 
    '2100-01-01'
FROM ods_sales.ods_customer t1
CROSS JOIN 
    (SELECT COALESCE(MAX(customer_sk),0) sk_max 
    FROM dw_sales.dim_customer) t2;
    
-- 装载产品维度表
INSERT INTO dw_sales.dim_product (product_sk,product_code,product_name,product_category,`version`,effective_date,expiry_date)
SELECT row_number() over (ORDER BY t1.product_code) + t2.sk_max,
    product_code, 
    product_name, 
    product_category, 
    1,
    '2019-01-03', 
    '2100-01-01'
FROM ods_sales.ods_product t1
CROSS JOIN
    (SELECT COALESCE(MAX(product_sk),0) sk_max 
    FROM dw_sales.dim_product) t2;
    
-- 装载订单维度表
INSERT INTO dw_sales.dim_order(order_sk,order_number,`version`,effective_date,expiry_date)
SELECT row_number() over (ORDER BY t1.order_number) + t2.sk_max,
    order_number, 
    1, 
    order_date, 
    '2100-01-01'
FROM ods_sales.ods_sales_order t1
CROSS JOIN
    (SELECT COALESCE(MAX(order_sk),0) sk_max 
    FROM dw_sales.dim_order) t2;
    
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

-- 装载销售订单事实表
INSERT INTO dw_sales.fact_sales_order  partition(order_date) 
SELECT order_sk as order_sk, 
    customer_sk as customer_sk, 
    product_sk as product_sk, 
    date_sk as order_date_sk, 
    order_amount as order_amount,
    a.order_date as order_date
FROM ods_sales.ods_sales_order a
JOIN dw_sales.dim_order b ON a.order_number = b.order_number
JOIN dw_sales.dim_customer c ON a.customer_number = c.customer_number
JOIN dw_sales.dim_product d ON a.product_code = d.product_code
JOIN dw_sales.dim_date e ON (a.order_date) = e.date_value;
