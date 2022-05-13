USE mysql_exercise

SELECT Concat(vend_name, ' (', vend_country, ')')
FROM vendors
ORDER BY vend_name;

SELECT Concat(RTrim(vend_name), ' (', RTrim(vend_country), ')')
FROM vendors
ORDER BY vend_name;

SELECT Concat(RTrim(vend_name), ' (', RTrim(vend_country), ')') AS vend_title
FROM vendors
ORDER BY vend_name;

SELECT prod_id, quantity, item_price
FROM orderitems
WHERE order_num = 20005;

SELECT prod_id,
       quantity,
       item_price,
       quantity * item_price AS expanded_price
FROM orderitems
WHERE order_num = 20005;