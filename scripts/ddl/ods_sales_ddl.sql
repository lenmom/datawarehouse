/*==============================================================*/
/* DBMS name:      Hive                                         */
/* Created on:     2018/11/23 1:09:10                           */
/*==============================================================*/
CREATE DATABASE IF NOT EXISTS ods_sales;

USE ods_sales;

/*==============================================================*/
/* Table: ods_customer                                          */
/*==============================================================*/
DROP TABLE IF EXISTS ods_sales.ods_customer;
CREATE TABLE ods_sales.ods_customer
(
   customer_number      INT ,
   customer_name        VARCHAR(128)  ,
   customer_street_address VARCHAR(256)  ,
   customer_zip_code    INT  ,
   customer_city        VARCHAR(32)  ,
   customer_state       VARCHAR(32)  
);

/*==============================================================*/
/* Table: ods_product                                           */
/*==============================================================*/
DROP TABLE IF EXISTS ods_sales.ods_product;
CREATE TABLE ods_sales.ods_product
(
   product_code         INT,
   product_name         VARCHAR(128)  ,
   product_category     VARCHAR(256)  
);

/*==============================================================*/
/* Table: ods_sales_order                                       */
/*==============================================================*/
DROP TABLE IF EXISTS ods_sales.ods_sales_order;
CREATE TABLE ods_sales.ods_sales_order
(
   order_number         INT ,
   customer_number      INT,
   product_code         INT ,
   order_date           timestamp  ,
   entry_date           timestamp  ,
   order_amount         DECIMAL(18,2)  
);


DROP TABLE IF EXISTS  ods_sales.ods_cdc_time ;
CREATE TABLE  ods_sales.ods_cdc_time
( 
   last_load date,
   current_load date
);


