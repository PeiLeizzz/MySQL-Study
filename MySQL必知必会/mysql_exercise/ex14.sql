USE mysql_exercise;

SELECT order_num
FROM orderitems
WHERE prod_id = 'TNT2';

SELECT cust_id
FROM orders
WHERE order_num IN (20005, 20007);

SELECT cust_id
FROM orders
WHERE order_num IN (
    SELECT order_num
    FROM orderitems
    WHERE prod_id = 'TNT2'
);

SELECT cust_name, cust_contact
FROM customers
WHERE cust_id IN (10001, 10004);

SELECT cust_name, cust_contact
FROM customers
WHERE cust_id IN (
    SELECT cust_id
    FROM orders
    WHERE order_num IN (
        SELECT order_num
        FROM orderitems
        WHERE prod_id = 'TNT2'
    )
);

SELECT COUNT(*) AS orders
FROM orders
WHERE cust_id = 10001;

SELECT cust_name, 
       cust_state,
       (SELECT COUNT(*)
        FROM orders
        WHERE orders.cust_id = customers.cust_id) AS orders
FROM customers
ORDER BY cust_name;