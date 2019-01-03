#!/bin/bash
# 建立Sqoop增量导入作业，以order_number作为检查列，初始的last-value是0
sqoop job --delete ods_incremental_import_job
sqoop job --create ods_incremental_import_job \
-- \
import \
--connect "jdbc:mysql://127.0.0.1:3306/mysql_sales_source?useSSL=false&user=root&password=root" \
--table sales_order \
--columns "order_number, customer_number, product_code, order_date, entry_date, order_amount"
\ --hive-import \
--hive-table ods_sales.ods_sales_order \
--incremental append \
--check-column order_number \
--last-value 0

# 首次抽取，将全部数据导入ODS库
# 首次抽取，将mysql中customer数据全部抽取到ods_sales.ods_customer中
sqoop import --connect jdbc:mysql://127.0.0.1:3306/sales_source?useSSL=false --username root --password root \
--table customer --hive-import --hive-table ods_sales.ods_customer --hive-overwrite
# 首次抽取，将mysql中product数据全部抽取到ods_sales.ods_product中
sqoop import --connect jdbc:mysql://127.0.0.1:3306/sales_source?useSSL=false --username root --password root \
--table product --hive-import --hive-table ods_sales.ods_product --hive-overwrite
# 删除dw_sales库中dw_sales.fact_sales_order数据清空，确保幂等性
beeline -u jdbc:hive2://127.0.0.1:10000/dw_sales -e "TRUNCATE TABLE dw_sales.fact_sales_order;"
# 执行增量导入ods_sales.ods_sales_order，因为last-value初始值为0，所以此次会导入全部数据
sqoop job --exec ods_incremental_import_job
# 调用init_etl.sql文件执行初始装载:将ods_sales中数据导入到dw_sales
beeline -u jdbc:hive2://127.0.0.1:10000/dw_sales -f init_dw_etl.sql