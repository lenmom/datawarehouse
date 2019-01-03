#!/bin/bash
# 整体拉取customer、product表数据
sqoop import --connect jdbc:mysql://cdh1:3306/mysql_sales_source?useSSL=false --username root --password \
root --table mysql_sales_source.customer --hive-import --hive-table ods_sales.ods_customer --hive-overwrite

sqoop import --connect jdbc:mysql://cdh1:3306/mysql_sales_source?useSSL=false --username root --password \
root --table mysql_sales_source.product --hive-import --hive-table ods_sales.ods_product --hive-overwrite

# 执行增量导入表ods_sales.ods_sales_order
sqoop job --exec myjob_incremental_import

# 调用 regular_etl.sql 文件执行定期装载数据库dw_sales中的所有表
beeline -u jdbc:hive2://127.0.0.1:10000/dw_sales -f schedule_daily_etl.sql