USE mysql_exercise;

SELECT prod_name
FROM products;

SELECT prod_id, prod_name, prod_price
FROM products;

SELECT *
FROM products;

SELECT vend_id
FROM products;

SELECT DISTINCT vend_id
FROM products;

-- 默认是对所有列进行去重，只有一行中两个列都相同，才会被过滤
-- 例如 (a, b) 和 (a, b)
SELECT DISTINCT vend_id, prod_price
FROM products;

SELECT prod_name
FROM products
LIMIT 5;

SELECT prod_name
FROM products
LIMIT 0, 5;

SELECT prod_name
FROM products
LIMIT 5 OFFSET 0;

SELECT products.prod_name
FROM products;

SELECT products.prod_name
FROM crashcourse.products;