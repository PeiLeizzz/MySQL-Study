USE mysql_exercise;

SELECT Concat(RTrim(vend_name), ' (', RTrim(vend_country), ')') AS vend_title
FROM vendors
ORDER BY vend_name;

SELECT cust_name, cust_contact
FROM customers AS c, orders AS o, orderitems AS oi
WHERE c.cust_id = o.cust_id
AND oi.order_num = o.order_num
AND prod_id = 'TNT2';

SELECT prod_id, prod_name
FROM products
WHERE vend_id = (
    SELECT vend_id
    FROM products
    WHERE prod_id = "DTNTR"
);

SELECT p1.prod_id, p1.prod_name
FROM products AS p1, products AS p2
WHERE p1.vend_id = p2.vend_id
AND p2.prod_id = 'DTNTR';

SELECT c.*, o.order_num, o.order_date, oi.prod_id, oi.quantity, oi.item_price
FROM customers AS c, orders AS o, orderitems AS oi
WHERE c.cust_id = o.cust_id
AND oi.order_num = o.order_num
AND prod_id = 'FB';

SELECT customers.cust_id, orders.order_num
FROM customers
INNER JOIN orders
ON customers.cust_id = orders.cust_id;

SELECT customers.cust_id, orders.order_num
FROM customers
LEFT OUTER JOIN orders
ON customers.cust_id = orders.cust_id;

SELECT customers.cust_id, orders.order_num
FROM orders
RIGHT OUTER JOIN customers
ON orders.cust_id = customers.cust_id;

SELECT customers.cust_name,
       customers.cust_id,
       COUNT(orders.order_num) AS num_ord
FROM customers
INNER JOIN orders
ON customers.cust_id = orders.cust_id
GROUP BY customers.cust_id, customers.cust_name;

SELECT customers.cust_name,
       customers.cust_id,
       COUNT(orders.order_num) AS num_ord
FROM customers
LEFT JOIN orders
ON customers.cust_id = orders.cust_id
GROUP BY customers.cust_id, customers.cust_name;