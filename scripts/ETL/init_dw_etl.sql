USE dw_sales;

-- 清空表
TRUNCATE TABLE dw_sales.dim_customer;
TRUNCATE TABLE dw_sales.dim_product;
TRUNCATE TABLE dw_sales.dim_order;
TRUNCATE TABLE dw_sales.fact_sales_order;

-- 装载客户维度表
INSERT INTO dw_sales.customer_dim (customer_sk,customer_number,customer_name,customer_street_address,customer_zip_code,customer_city,customer_state,`version`,effective_date,expiry_date)
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
FROM ods_sales.ods_ods_customer t1
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
    FROM dw_sales.product_dim) t2;
    
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
    
-- 装载销售订单事实表
INSERT INTO dw_sales.fact_sales_order()
SELECT order_sk, 
    customer_sk, 
    product_sk, 
    date_sk, 
    order_amount
FROM ods_sales.ods_sales_order a
JOIN dw_sales.dim_order b ON a.order_number = b.order_number
JOIN dw_sales.dim_customer c ON a.customer_number = c.customer_number
JOIN dw_sales.dim_product d ON a.product_code = d.product_code
JOIN dw_sales.dim_date e ON (a.order_date) = e.date_value;
