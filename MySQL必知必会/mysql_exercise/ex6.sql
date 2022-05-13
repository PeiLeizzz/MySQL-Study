USE mysql_exercise;

SELECT prod_name, prod_price
FROM products
WHERE prod_price = 2.50;

SELECT prod_name, prod_price
FROM products
WHERE prod_name = 'fuses';

SELECT prod_name, prod_price
FROM products
WHERE prod_price < 10;

SELECT prod_name, prod_price
FROM products
WHERE prod_price <= 10;

SELECT vend_id, prod_name
FROM products
WHERE vend_id <> 1003;

SELECT vend_id, prod_name
FROM products
WHERE vend_id != 1003;

SELECT prod_name, prod_price
FROM products
WHERE prod_price BETWEEN 5 AND 10;

SELECT prod_name
FROM products
WHERE prod_price IS NULL;

SELECT cust_id
FROM customers
WHERE cust_email IS NULL;