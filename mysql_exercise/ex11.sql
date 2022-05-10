USE mysql_exercise;

SELECT vend_name, Upper(vend_name) AS vend_name_upcase
FROM vendors
ORDER BY vend_name;

SELECT cust_name, cust_contact
FROM customers
WHERE cust_contact = 'Y. Lie';

SELECT cust_name, cust_contact
FROM customers
WHERE Soundex(cust_contact) = Soundex('Y. Lie');

SELECT cust_id, order_num
FROM orders
WHERE order_date = '2005-09-01';

SELECT cust_id, order_num
FROM orders
WHERE Date(order_date) = '2005-09-01';

SELECT cust_id, order_num
FROM orders
WHERE Date(order_date) BETWEEN '2005-09-01' AND '2005-09-30';

SELECT cust_id, order_num
FROM orders
WHERE Year(order_date) = 2005 AND Month(order_date) = 9;

SELECT Date(order_date) AS date
FROM orders