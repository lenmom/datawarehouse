create database IF NOT EXISTS dw_sales;

USE dw_sales;

DROP TABLE IF EXISTS dw_sales.dim_product;
CREATE TABLE dw_sales.dim_product
(
   product_sk           int   ,
   product_code         int ,
   product_name         varchar(128),
   product_category     varchar(256),
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (product_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');
/*==============================================================*/
/* Table: dim_customer                                          */
/*==============================================================*/
DROP TABLE IF EXISTS dw_sales.dim_customer;
CREATE TABLE dw_sales.dim_customer
(
   customer_sk          int   ,
   customer_number      int ,
   customer_name        varchar(128),
   customer_street_address varchar(256),
   customer_zip_code    int,
   customer_city        varchar(32),
   customer_state       varchar(32),
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (customer_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');

/*==============================================================*/
/* Table: dim_date                                              */
/*==============================================================*/
DROP TABLE IF EXISTS dw_sales.dim_date;
CREATE TABLE dw_sales.dim_date
(
   date_sk              int,
   date_value           date,
   month                tinyint,
   month_name           varchar(16),
   quarter              tinyint,
   year                 int
) row format delimited fields terminated by ','
stored as textfile;

/*==============================================================*/
/* Table: dim_order                                             */
/*==============================================================*/
DROP TABLE IF EXISTS  dw_sales.dim_order;
CREATE TABLE dw_sales.dim_order
(
   order_sk             int  ,
   order_number         int,
   version              varchar(32),
   effective_date       date,
   expiry_date          date
)
clustered by (order_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');


/*==============================================================*/
/* Table: fact_sales_order                                      */
/*==============================================================*/
DROP TABLE IF EXISTS  dw_sales.fact_sales_order;
CREATE TABLE dw_sales.fact_sales_order
(
   order_sk             int  ,
   customer_sk          int  ,
   product_sk           int  ,
   order_date_sk        int  ,
   order_amount         decimal(18,2)
)
partitioned by(order_date string)
clustered by (order_sk ) into 8 buckets
stored as orc tblproperties('transactional'='true');

