USE mysql_exercise;

CREATE TABLE productnotes (
    note_id int NOT NULL AUTO_INCREMENT,
    prod_id char(10) NOT NULL,
    note_date datetime NOT NULL,
    note_text text NULL,
    PRIMARY KEY(note_id),
    FULLTEXT(note_text)
) ENGINE=MyISAM;

SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('rabbit');

SELECT note_text
FROM productnotes
WHERE note_text LIKE '%rabbit%';

SELECT note_text, 
       Match(note_text) Against('rabbit') AS rank
FROM productnotes;

SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('anvils');

SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('anvils' WITH QUERY EXPANSION);

SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('heavy' IN BOOLEAN MODE);

-- 排除以 rope 开头的任何文本
SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('heavy -rope*' IN BOOLEAN MODE);

-- 匹配 rabbit / bait 任意一个
SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('rabbit bait' IN BOOLEAN MODE);

-- 匹配 "rabbit bait" 短语
SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('"rabbit bait"' IN BOOLEAN MODE);

-- 增加 rabbit 的优先级，降低 carrot 的优先级
SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('>rabbit <carrot' IN BOOLEAN MODE);

-- 匹配 safe 和 combination，降低 combination 优先级
SELECT note_text
FROM productnotes
WHERE Match(note_text) Against('+safe +(<combination)' IN BOOLEAN MODE);