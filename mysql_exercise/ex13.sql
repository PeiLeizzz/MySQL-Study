USE mysql_exercise;

SELECT COUNT(*) AS num_prods
FROM products
WHERE vend_id = 1003;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
GROUP BY vend_id;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
GROUP BY vend_id WITH ROLLUP;

SELECT vend_id + 1 AS vend_id_add, prod_id, COUNT(*) AS num_prods
FROM products
GROUP BY vend_id, prod_id, NULL;

SELECT cust_id, COUNT(*) AS orders
FROM orders
GROUP BY cust_id
HAVING COUNT(*) >= 2;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
WHERE prod_price >= 10
GROUP BY vend_id
HAVING COUNT(*) >= 2;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
WHERE prod_price >= 10
GROUP BY vend_id WITH ROLLUP
HAVING COUNT(*) >= 2;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
WHERE prod_price >= 10
GROUP BY vend_id WITH ROLLUP
HAVING COUNT(*) >= 2 AND COUNT(*) <= 5;

SELECT vend_id, COUNT(*) AS num_prods
FROM products
GROUP BY vend_id
HAVING COUNT(*) >= 2;

SELECT order_num, SUM(quantity * item_price) AS ordertotal
FROM orderitems
GROUP BY order_num
HAVING SUM(quantity * item_price) >= 50;

SELECT order_num, SUM(quantity * item_price) AS ordertotal
FROM orderitems
GROUP BY order_num
HAVING SUM(quantity * item_price) >= 50
ORDER BY ordertotal;