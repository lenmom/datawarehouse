/*==============================================================*/
/* DBMS name:      MySQL 5.0                                    */
/* Created on:     2018/11/23 1:09:10                           */
/*==============================================================*/
CREATE DATABASE IF NOT EXISTS mysql_sales_source DEFAULT CHARSET utf8 COLLATE utf8_general_ci; 

USE mysql_sales_source;

/*==============================================================*/
/* Table: customer                                              */
/*==============================================================*/
DROP TABLE IF EXISTS mysql_sales_source.customer;
CREATE TABLE mysql_sales_source.customer
(
   customer_number      INT(11) NOT NULL AUTO_INCREMENT,
   customer_name        VARCHAR(128) NOT NULL,
   customer_street_address VARCHAR(256) NOT NULL,
   customer_zip_code    INT(11) NOT NULL,
   customer_city        VARCHAR(32) NOT NULL,
   customer_state       VARCHAR(32) NOT NULL,
   PRIMARY KEY (customer_number)
);

/*==============================================================*/
/* Table: product                                               */
/*==============================================================*/
DROP TABLE IF EXISTS mysql_sales_source.product;
CREATE TABLE product
(
   product_code         INT(11) NOT NULL AUTO_INCREMENT,
   product_name         VARCHAR(128) NOT NULL,
   product_category     VARCHAR(256) NOT NULL,
   PRIMARY KEY (product_code)
);

/*==============================================================*/
/* Table: sales_order                                           */
/*==============================================================*/
DROP TABLE IF EXISTS mysql_sales_source.sales_order;
CREATE TABLE mysql_sales_source.sales_order
(
   order_number         INT(11) NOT NULL AUTO_INCREMENT,
   customer_number      INT(11) NOT NULL,
   product_code         INT(11) NOT NULL,
   order_date           DATETIME NOT NULL,
   entry_date           DATETIME NOT NULL,
   order_amount         DECIMAL(18,2) NOT NULL,
   PRIMARY KEY (order_number)
);

/*==============================================================*/
/* insert data                                        */
/*==============================================================*/

INSERT INTO mysql_sales_source.customer
( customer_name
, customer_street_address
, customer_zip_code
, customer_city
, customer_state
 )
VALUES
  ('Big Customers', '7500 Louise Dr.', '17050','Mechanicsburg', 'PA')
, ( 'Small Stores', '2500 Woodland St.', '17055', 'Pittsburgh', 'PA')
, ('Medium Retailers', '1111 Ritter Rd.', '17055','Pittsburgh', 'PA')
,  ('Good Companies', '9500 Scott St.', '17050','Mechanicsburg', 'PA')
, ('Wonderful Shops', '3333 Rossmoyne Rd.', '17050','Mechanicsburg', 'PA')
, ('Loyal Clients', '7070 Ritter Rd.', '17055','Pittsburgh', 'PA');
	   
	   
INSERT INTO mysql_sales_source.product(product_name,product_category) VALUES
('Hard Disk','Storage'),
('Floppy Drive','Storage'),
('lcd panel','monitor');



DROP PROCEDURE  IF EXISTS usp_generate_order_data;
DELIMITER //
CREATE PROCEDURE usp_generate_order_data()
BEGIN

	DROP TABLE IF EXISTS mysql_sales_source.tmp_sales_order;
	CREATE TABLE tmp_sales_order AS SELECT * FROM mysql_sales_source.sales_order WHERE 1=0;
	SET @start_date := UNIX_TIMESTAMP('2018-1-1');
	SET @end_date := UNIX_TIMESTAMP('2018-11-23');
	SET @i := 1;
	WHILE @i<=10000 DO
		SET @customer_number := FLOOR(1+RAND()*6);
		SET @product_code := FLOOR(1+RAND()* 3);
		SET @order_date := FROM_UNIXTIME(@start_date+RAND()*(@end_date-@start_date));
		SET @amount := FLOOR(1000+RAND()*9000);
		INSERT INTO mysql_sales_source.tmp_sales_order VALUES (@i,@customer_number,@product_code,@order_date,@order_date,@amount);
		SET @i := @i +1;
	END WHILE;
	TRUNCATE TABLE mysql_sales_source.sales_order;
	INSERT INTO mysql_sales_source.sales_order
	SELECT NULL,customer_number,product_code,order_date,entry_date,order_amount
	FROM mysql_sales_source.tmp_sales_order;
	COMMIT;
	DROP TABLE IF EXISTS mysql_sales_source.tmp_sales_order;
END;
//
DELIMITER ;
CALL usp_generate_order_data();