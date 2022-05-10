USE mysql_exercise;

SELECT prod_id, prod_name
FROM products
WHERE prod_name LIKE 'jet%';

SELECT prod_id, prod_name
FROM products
WHERE prod_name LIKE '%anvil%';

SELECT prod_name
FROM products
WHERE prod_name LIKE 's%e';

SELECT prod_id, prod_name
FROM products
WHERE prod_name LIKE '_ ton anvil';

SELECT prod_id, prod_name
FROM products
WHERE prod_name LIKE '% ton_anvil';