-- 设置scd的生效时间和过期时间
SET hivevar:cur_date = CURRENT_DATE(); 
SET hivevar:pre_date = DATE_ADD(${hivevar:cur_date},-1);
SET hivevar:max_date = CAST('2100-01-01' AS DATE);

-- 设置cdc的开始结束日期
INSERT overwrite TABLE ods_sales.ods_cdc_time
SELECT last_load, ${hivevar:cur_date} 
FROM ods_sales.ods_cdc_time;

-- 装载customer维度
-- 获取源数据中被删除的客户和地址发生改变的客户，将这些数据设置为过期时间，即当前时间的前一天
UPDATE dw_sales.dim_customer
SET expiry_date = ${hivevar:pre_date}
WHERE dw_sales.dim_customer.customer_sk IN
(  SELECT  a.customer_sk
   FROM 
       (SELECT
            customer_sk,
            customer_number,
            customer_street_address
        FROM dw_sales.dim_customer
        WHERE expiry_date = ${hivevar:max_date}
	    ) AS a
        LEFT JOIN ods_sales.ods_customer AS b 
		ON a.customer_number = b.customer_number
        WHERE b.customer_number IS NULL
              OR a.customer_street_address <> b.customer_street_address
);

-- 将有地址变化的插入到dim_customer表，如果有相同数据存在有不过期的数据则不插入
INSERT INTO dw_sales.dim_customer
SELECT row_number() over (ORDER BY t1.customer_number) + t2.sk_max,
	t1.customer_number,
	t1.customer_name,
	t1.customer_street_address,
	t1.customer_zip_code,
	t1.customer_city,
	t1.customer_state,
	t1.version,
	t1.effective_date,
	t1.expiry_date
FROM(SELECT
	    t2.customer_number customer_number,
	    t2.customer_name customer_name,
	    t2.customer_street_address customer_street_address,
	    t2.customer_zip_code,
	    t2.customer_city,
	    t2.customer_state,
	    t1.version + 1 `version`,
	    ${hivevar:pre_date} effective_date,
	    ${hivevar:max_date} expiry_date
    FROM dw_sales.dim_customer t1
    INNER JOIN ods_sales.ods_customer t2 ON t1.customer_number = t2.customer_number
		    AND t1.expiry_date = ${hivevar:pre_date}
    LEFT JOIN dw_sales.dim_customer t3 ON t1.customer_number = t3.customer_number
			AND t3.expiry_date = ${hivevar:max_date}
    WHERE t1.customer_street_address <> t2.customer_street_address 
	        AND t3.customer_sk IS NULL
) t1
CROSS JOIN
(SELECT COALESCE(MAX(customer_sk),0) sk_max FROM dw_sales.dim_customer) t2;
	  

-- 处理customer_name列上的scd1，覆盖
-- 不进行更新，将源数据中的name列有变化的数据提取出来，放入临时表
-- 将 dim_couster中这些数据删除、
-- 将临时表中的数据插入
DROP TABLE IF EXISTS tmp;
CREATE TABLE tmp AS
SELECT a.customer_sk,
	a.customer_number,
	b.customer_name,
	a.customer_street_address,
	a.customer_zip_code,
	a.customer_city,
	a.customer_state,
	a.version,
	a.effective_date,
	a.expiry_date
FROM dw_sales.dim_customer a 
JOIN ods_sales.ods_customer b 
ON  a.customer_number = b.customer_number 
    AND(a.customer_name <> b.customer_name);

-- 删除数据			
DELETE FROM
dw_sales.dim_customer WHERE
dw_sales.dim_customer.customer_sk IN (SELECT customer_sk FROM tmp);

-- 插入数据
INSERT INTO dw_sales.dim_customer 
SELECT * FROM tmp;



-- 处理新增的customer记录
INSERT INTO dw_sales.dim_customer
SELECT row_number() over (ORDER BY t1.customer_number) + t2.sk_max,
	t1.customer_number,
	t1.customer_name,
	t1.customer_street_address,
	t1.customer_zip_code,
	t1.customer_city,
	t1.customer_state,
	1,
	${hivevar:pre_date},
	${hivevar:max_date}
FROM( SELECT t1.* 
	FROM ods_sales.ods_customer t1 
	LEFT JOIN dw_sales.dim_customer t2 ON t1.customer_number = t2.customer_number
WHERE t2.customer_sk IS NULL ) AS t1
CROSS JOIN
(SELECT COALESCE(MAX(customer_sk),0) sk_max  FROM dw_sales.dim_customer) AS t2;
---------------------------------------------------------------------------------------------------------------
-- 装载product维度
-- 取源数据中删除或者属性发生变化的产品，将对应
UPDATE dw_sales.dim_product
SET expiry_date = ${hivevar:pre_date}
WHERE dw_sales.dim_product.product_sk IN
(   SELECT a.product_sk
	FROM
	    (SELECT product_sk,
				product_code,
				product_name,
				product_category
		FROM dw_sales.dim_product 
		WHERE expiry_date = ${hivevar:max_date}
		)  AS a 
		LEFT JOIN ods_sales.ods_product b ON a.product_code = b.product_code
		WHERE b.product_code IS NULL 
		      OR (a.product_name <> b.product_name OR a.product_category <> b.product_category)
);
					
-- 处理product_name、product_category列上scd2的新增行
INSERT INTO dw_sales.dim_product
SELECT row_number() over (ORDER BY t1.product_code) + t2.sk_max,
	t1.product_code,
	t1.product_name,
	t1.product_category,
	t1.version,
	t1.effective_date,
	t1.expiry_date
FROM
( SELECT t2.product_code product_code,
		t2.product_name product_name,
		t2.product_category product_category,
		t1.version + 1 `version`,
		${hivevar:pre_date} effective_date,
		${hivevar:max_date} expiry_date
FROM dw_sales.dim_product t1
INNER JOIN ods_sales.ods_product t2 ON t1.product_code = t2.product_code AND t1.expiry_date = ${hivevar:pre_date}
LEFT JOIN dw_sales.dim_product t3 ON t1.product_code = t3.product_code  AND t3.expiry_date = ${hivevar:max_date}
WHERE(t1.product_name <> t2.product_name 
	OR t1.product_category <> t2.product_category) 
	AND t3.product_sk IS NULL
) as t1
CROSS JOIN 
(SELECT COALESCE(MAX(product_sk),0) sk_max FROM dw_sales.dim_product) as t2;


-- 处理新增的 product 记录
INSERT INTO dw_sales.dim_product
SELECT row_number() over (ORDER BY t1.product_code) + t2.sk_max,
	t1.product_code,
	t1.product_name,
	t1.product_category,
	1,
	${hivevar:pre_date},
	${hivevar:max_date}
FROM
( SELECT t1.* 
	FROM ods_sales.ods_product t1 
	LEFT JOIN dw_sales.dim_product t2 ON t1.product_code = t2.product_code
	WHERE t2.product_sk IS NULL
) t1
CROSS JOIN 
(SELECT COALESCE(MAX(product_sk),0) sk_max FROM dw_sales.dim_product) t2;
---------------------------------------------------------------------------------------------------------------
-- 装载order维度
INSERT INTO dw_sales.dim_order
SELECT row_number() over (ORDER BY t1.order_number) + t2.sk_max,
	t1.order_number,
	t1.version,
	t1.effective_date,
	t1.expiry_date
FROM
(  
    SELECT order_number order_number,
		1 `version`,
		order_date effective_date,
		'2050-01-01' expiry_date
    FROM ods_sales.ods_sales_order, ods_sales.ods_cdc_time 
    WHERE entry_date >= last_load AND entry_date < current_load 
) t1
CROSS JOIN
(SELECT COALESCE(MAX(order_sk),0) sk_max FROM dw_sales.dim_order) t2;
---------------------------------------------------------------------------------------------------------------

-- 装载销售订单事实表
INSERT INTO dw_sales.fact_sales_order
SELECT order_sk,
	   customer_sk,
	   product_sk,
	   date_sk,
	   order_amount
FROM ods_sales.ods_sales_order a,
	dw_sales.dim_order b,
	dw_sales.dim_customer c,
	dw_sales.dim_product d,
	dw_sales.dim_date e,
	ods_sales.ods_cdc_time f
WHERE a.order_number = b.order_number
	AND a.customer_number = c.customer_number
	AND a.order_date >= c.effective_date
	AND a.order_date < c.expiry_date
	AND a.product_code = d.product_code
	AND a.order_date >= d.effective_date
	AND a.order_date < d.expiry_date
	AND to_date(a.order_date) = e.date_value
	AND a.entry_date >= f.last_load 
	AND a.entry_date < f.current_load ;
---------------------------------------------------------------------------------------------------------------
-- 更新时间戳表的last_load字段
INSERT overwrite TABLE ods_sales.ods_cdc_time 
SELECT current_load, current_load 
FROM ods_sales.ods_cdc_time;