## MySQL

### SELECT 语句构建顺序
- SELECT [DISTINCT]
- FROM
- [INNER|LEFT|RIGHT] JOIN...ON
- WHERE
- GROUP BY
- HAVING
- ORDER BY
- LIMIT

### 语法
- `DISTINCT`：
  - 只能在 `SELECT` 中使用；
  - 必须放在所有字段最前面；
  - 如果后跟多个字段，则是对所有字段的组合进行去重
- `JOIN...ON`：`ON` 条件是在生成临时表时使用的条件，而 `WHERE` 是在临时表生成后进行过滤。在一个联结中可以包含多个表，甚至对于每个联结可以采用不同的联结类型。
  - `INNER JOIN`：只返回**两个表中联结字段相等**的行，返回所有数据，甚至相同的列多次出现。可以通过 `SELECT` 指定列名来去除重复列（自然联结）
  - `LEFT JOIN`：返回**左表中所有记录和右表中联结字段相等**的记录
  - `RIGHT JOIN`：返回**右表中所有记录和左表中联结字段相等**的记录
- `WHERE`：
  - 字符串比较时默认不区分大小写 `'fuses' = 'Fuses'`
  - `BETWEEN start AND end`：限定的是闭区间 `[start, end]`，也可以用于日期
  - `NULL` 只能用 `IS` 匹配，`= < >` 等操作符不会返回 `NULL` 值
  - `NOT`：MySQL 支持使用 `NOT` 对 `IN、BETWEEN、EXISTS` 子句取反
  - `LIKE` 谓词：
    - `%` 通配符，表示任何字符出现任意次数（包含 0 次），但不能匹配 `NULL`
    - `_` 通配符，匹配单个任意字符
    - 把通配符用在搜索的最开始处，是最慢的
  - `REGEXP` 正则表达式支持：MySQL 仅支持多数正则表达式实现的一个很小的子集
    - `REGEXP BINARY` 区分大小写
    - `.` 通配符，匹配单个任意字符
    - `|`：或（`OR`）操作符
    - `[]`：定义一组字符，匹配其中任意一个，`[123]` 等价于 `[1|2|3]`
    - `^`（集合中使用）：否定，不匹配，`[^123]` 意为不匹配 `1、2、3`
    - `[0-9a-zA-Z]`：范围匹配
    - `\\`：转义，用于匹配特殊字符，如果要匹配 `\`，需要使用 `\\\`（MySQL 要求两斜杠是由于 MySQL 自己解释一个、正则表达式库解释另一个）
    - `[[:alnum:]] [[:alpha:]]` 等是预定义的字符类
    - 重复元字符：
      - `*`：0 或多个匹配
      - `+`：1 或多个匹配（等于 `{1,}`）
      - `?`：0 或 1 个匹配（等于 `{0,1}`）
      - `{n}`：n 个匹配
      - `{n,}`：不少于 n 个的匹配
      - `{n,m}`：匹配数目的范围（m 不超过 255）
    - 定位符：
      - `^`（集合外使用）：文本的开始，`^[123]` 意为以 `1/2/3` 开头
      - `$`：文本的结尾
      - `[[:<:]]`：词的开始
      - `[[:>:]]`：词的结尾
  - 子查询：
    - 在 `WHERE` 子句中使用子查询，应该保证子查询的 `SELECT` 语句具有与 `WHERE` 子句中相同数目的列
- `GROUP BY`：
  - `GROUP BY` 指示分组数据，然后对每个组而不是整个结果表使用聚集函数
  - `GROUP BY` 子句可以包含任意数目的列，这使得能对分组进行嵌套，为数据分组提供更细致的控制
  - `GROUP BY` 子句中列出的每个列必须是**检索列**或有效的**表达式**（但**不能是聚集函数**）
  - 除聚集计算语句外，`SELECT` 语句的每个列都必须在 `GROUP BY` 子句中给出
  - 如果分组列中具有 `NULL` 值，则将 `NULL` 作为一个分组返回列，如果列中有多行 `NULL`，它们将分为一组
  - 使用 `WITH ROLLUP` 关键字，可以得到每个分组以及对每个分组汇总级别（二次聚集）的值（作为新的一组返回）
  - `GROUP BY` 分组后的数据顺序无法保证，需要按序时要使用 `ORDER BY`
- `HAVING`：
  - `WHERE` 子句的语法都适用于 `HAVING` 子句，区别在于 `WHERE` 用于过滤行，而 `HAVING` 用于过滤分组（**`WHERE` 在数据分组前过滤，`HAVING` 在数据分组后过滤，`WHERE` 排除的值不会包括在分组中**）
  - `HAVING` 中要过滤的字段必须是在 `SELECT` 中出现的
- `ORDER BY`：
  - 默认是升序 `ASC`，用 `DESC` 指定降序
  - **可以指定非选中 (`SELECT`) 的列用于排序**
  - `ORDER BY a, b, c`：按多个列排序，优先级依次降低
  - `ORDER BY a DESC, b`：复合排序
  - 如果要在多个列上降序排列，则需要在每个列后跟 `DESC`
  - 大小写字母的顺序，例如 `A / a`，取决于数据库的设置（MySQL 中的顺序默认视为相同）
- `LIMIT`：
  - `LIMIT 5`：前 5 行（默认从第 0 行开始）
  - `LIMIT 8, 5`：从第 8 行开始，检索 5 行
  - `LIMIT 4 OFFSET 3`：从第 3 行开始，取 4 行，等同于 `LIMIT 3, 4`
  - 行数不够时，返回其能够返回的所有行
- 函数
  - 文本处理函数
    - 拼接 `Concat()`：例如需要将列 `name` 和列 `location` 以 `name(location)` 的格式查询出来，可以通过：
      ```sql
      SELECT Concat(name, ' (', location, ')')
      FROM vendors
      ```
    - 删除多余空格：
      - 删除左侧多余空格：`LTrim()`
      - 删除右侧多余空格：`RTrim()`
      - 删除左右多余空格：`Trim()`
    - 大小写转换函数：`Upper()` 和 `Lower()`
    - 字符串长度：`Length()`
    - 转换为语音表示的字母数字模式：`Soundex()`
    - 找出串的子串：`Locate()`
    - 返回子串的字符：`SubString()`
    - 返回串左/右的字符：`Left()` 和 `Right()`
  - 日期和时间处理函数（MySQL 中日期格式最好为 `yyyy-mm-dd`）
    - 返回当前日期：`CurDate()`
    - 返回当前时间：`CurTime()`
    - 返回当前日期和时间：`Now()`
    - 增加一个日期：`AddDate()`
    - 增加一个时间：`AddTime()`
    - 计算两个日期之差：`DateDiff()`
    - 高度灵活的日期运算函数：`Date_Add()`
    - 返回一个格式化的日期或时间串：`Date_Format()`
    - 返回一个日期的年份部分：`Year()`
    - 返回一个日期的月数部分：`Month()`
    - 返回一个日期的天数部分：`Day()`
    - 返回一个时间的小时部分：`Hour()`
    - 返回一个时间的分钟部分：`Minute()`
    - 返回一个时间的秒部分：`Second()`
    - 返回一个日期时间的日期部分：`Date()`
    - 返回一个日期时间的时间部分：`Time()`
    - 对于一个日期，返回对应的星期：`DayOfWeek()`
  - 数值处理函数
    - 绝对值：`Abs()`
    - 余弦：`Cos()`
    - 正弦：`Sin()`
    - 正切：`Tan()`
    - 平方根：`Sqrt()`
    - 余数：`Mod()`
    - 指数：`Exp()`
    - 圆周率：`Pi()`
    - 随机数：`Rand()`
  - 聚集函数：只能用于 `SELECT` 子句和 `GROUP BY` 中的 `HAVING` 子句；指定 `DISTINCT` 参数可以忽略重复行的计算
    - 返回某列的平均值：`AVG()`，其忽略值为 `NULL` 的行
    - 返回某列的行数：`COUNT()`
      - `COUNT(*)`：对**表**中行的数目进行计数，包含 `NULL`值；不能使用 `COUNT(DISTINCT)`
      - `COUNT(column)`：对特定**列**中**具有值**的行进行计数，忽略 `NULL` 值
    - 返回某列的最小值：`MIN()`，一般用于数值和日期，用于文本数据时，如果数据按相应的列排序，则返回第一行
    - 返回某列的最大值：`MAX()`，一般用于数值和日期，用于文本数据时，如果数据按相应的列排序，则返回最后一行
    - 返回某列值之和：`SUM()`，其忽略值为 `NULL` 的行
- 别名 `AS`
  - 表别名不仅能用于 `WHERE` 子句，还可以用于 `SELECT` 的列表，`ORDER BY` 子句以及语句的其他部分
  - 表别名不返回到客户机，而列别名会
  - 表别名的一个用处是，允许在单条 `SELECT` 语句中多次使用相同的表
- 组合查询：可以与多个 `WHERE` 条件构成的单查询互相转换，在不同场景下性能不同
  - `UNION`
    - 每个查询的列数据类型必须兼容，可以不必完全相同，但必须是 DBMS 可以隐含地转换的类型（例如不同的数值类型或不同的日期类型）
    - `UNION` 默认从查询结果集中去除重复的行（即行为与单条 `SELECT` 语句中使用多个 `WHERE` 条件一样）；如果想要匹配所有行，可以用 `UNION ALL`
    - 只能使用一条 `ORDER BY` 子句，且必须出现在最后一条 `SELECT` 语句之后
- 全文本搜索：`MyISAM` 支持，`InnoDB` 不支持
  - 为了进行全文本搜索，必须索引被搜索的列，而且要随着数据的改变不断地重新索引，在对表列进行适当设计后，MySQL 会自动进行所有的索引和重新索引
  - 通过创建表时 `FULLTEXT(column)` 来指定搜索列，其中可以索引单个列或多个列。定义之后，MySQL 自动维护该索引，在增加、更新或删除行时，索引随之自动更新
  - 也可以不在创建表时指定 `FULLTEXT`，可以稍后指定，但这种情况下所有已有数据必须立即索引
  - 使用两个函数 `Match()` 和 `Against()` 执行全文搜索，其中 `Match()` 指定被索引的列（必须与 `FULLTEXT()` 中定义的相同，次序也要相同），`Against()` 指定要使用的搜索表达式
  - 除非使用 `BINARY` 方式，否则全文本搜索不区分大小写
  - 全文搜索返回**以文本匹配的良好程度排序的数据**
  - 查询扩展（`Against('text' WITH QUERY EXPANSION`）：查询扩展用来设法放宽所返回的全文本搜索结果的范围，在使用查询扩展时，MySQL 对数据和索引进行**两遍扫描**来完成搜索
    - 首先，进行一个基本的全文本搜索，找出与搜索条件匹配的所有行
    - 其次，MySQL 检查这些匹配行并选择所有有用的词
    - 再其次，MySQL 再次进行全文本搜索，这次不仅使用原来的条件，而且还使用所有有用的词
  - 布尔搜索（`Against('text' IN BOOLEAN MODE`）：即使没有 `FULLTEXT` 索引也可以用，可提供关于下面内容的细节：
    - 要匹配的词 `+`
    - 要排斥的词 `-`
    - 排列提示（指定某些词比其他词更重要）`> <`
    - 表达式分组 `()`
    - ...
    - 在布尔排序中，不按优先级降序返回
- `INSERT INTO`
  - 插入完整的行
  - 插入行的一部分，省略的列必须满足的条件：允许为 `NULL` 值 / 表定义中有默认值
  - 插入多行：每组值用 `()` 括起来，用 `,` 分隔，属于同一条 `INSERT` 语句
  - 插入某些查询的结果，`SELECT` 中的每个列的位置应该与 `INSERT INTO` 对应（列名可以不同）
- `UPDATE ... SET`
  - 更新表中特定行，多个列时用 `,` 分隔
  - 更新表中所有行
  - 删除指定列 `SET ... = NULL`
  - 如果更新多行，过程中出现了错误，会取消整个 `UPDATE` 过程，可以通过 `IGNORE` 关键字忽略中间出现的错误、继续进行更新
  
    `UPDATE IGNORE ... SET`
  - `UPDATE` 后可以跟多个表
  - `UPDATE` 可以使用子查询，但是要更新的表**不能**放在 `SET` 和 `WHERE` 子句中用于子查询，要放在 `UPDATE` 后面
- `DELETE FROM`
  - 从表中删除特定的行
  - 从表中删除所有行：可以使用 `TRUNCATE TABLE` 速度更快（原理是删除原来的表并创建一个新的表，而不是逐行函数）
- 表级操作
  - `CREATE TABLE`
    - `AUTO_INCREMENT` 只允许存在一个，并且必须被索引（例如，使它成为主键）；可以使用 `SELECT _last_insert_id()` 获得刚刚插入的自增值
    - `DEFAULT` MySQL 中不允许使用函数作为默认值，只支持常量
  - `ALTER TABLE ... ADD/DROP COLUMN`
  - `ALTER TABLE ... ADD/DROP CONSTRAINT`
  - `DROP TABLE`
  - `RENAME TABLE ... TO ...`
- 创建索引：
  ```sql
  CREATE INDEX indexname
  ON tablename (column [ASC|DESC], ...)
  ```
- MySQL 内置引擎：外键不能跨引擎使用
  - `InnoDB`：可靠的事务处理引擎，不支持全文本搜索
  - `MEMORY`：功能等同于 `MyISAM`，数据存储在内存，速度很快（特别适用于临时表）
  - `MyISAM`：性能极高的引擎，支持全文本搜索，但不支持事务
- 视图
  - 优点：
    - 重用 SQL 语句
    - 简化复杂 SQL
    - 使用表的组成部分而不是整个表
    - 保护数据，分离权限
    - 更改数据格式与表示
  - `CREATE VIEW ... AS ...`
  - `DROP VIEW`
- 事务
  - `START TRANSACTION`
  - `ROLLBACK`：只能作用于 `DELETE INSERT UPDATE`（不能作用于 `CREATE DROP`）
  - `COMMIT`
  - `SAVEPOINT`：保留点，可以回退到该点（而不是回退所有）
- 权限相关
  - 创建用户：`CREATE USER xxx IDENTIFIED BY 'xxx';`
  - 重命名用户：`RENAME USER xxx TO xxx;`
  - 删除用户：`DROP USER xxx;`
  - 修改用户密码：`SET PASSWORD FOR 用户名 = Password('密码');`
  - 更改自己的密码：`SET PASSWORD = Password('密码')`
  - 授权：`GRANT [权限名] ON [数据库名].[表名] TO '用户名'@'主机名';`
  - 撤销权限：`REVOKE ... FROM ...`

### 数据类型
- 串
  - `CHAR`：1～255 个字符的定长串，长度必须在创建时指定，否则默认为 `CHAR(1)`
  - `ENUM`：接受最多 64K 个串组成的一个预定义集合的某个串
  - `SET`：接受最多 64 个串组成的一个预定义集合的零个或多个串
  - `LONGTEXT`：与 `TEXT` 相同，但最大长度为 4GB
  - `MIDIUMTEXT`：与 `TEXT` 想同，但最大长度为 16K
  - `TEXT`：最大长度为 64K 的变长文本
  - `TINYTEXT`：与 `TEXT` 相同，但最大长度为 255 字节
  - `VARCHAR`：长度可变，最长不超过 255 字节，如果在创建时指定为 `VARCHAR(n)`，则可存储 0 到 n 个字符的**变长串**
- 数值：可以加上 `UNSIGNED` 指定为无符号数
  - `BIT`：位字段，1～64 位
  - `BIGINT`：整数值 `[-2^63~2^63-1]
  - `INT / INTEGER`：`[-2^31~2^31-1]
  - `MEDIUMINT`：`[-8388608~8388607]`
  - `SMALLINT`：`[-2^15~2^15-1]`
  - `TINYINT`：`[-128~127]`
  - `BOOLEAN / BOOL`：0 或 1
  - `DECIMAL / DEC`：精度可变的浮点值
  - `DOUBLE`：双精度浮点值
  - `FLOAT`：单精度浮点值
  - `REAL`：4 字节的浮点值
- 日期
  - `DATE`：`[1000-01-01~9999-12-31]`，格式为 `YYYY-MM-DD`
  - `DATETIME`：`DATE` 和 `TIME` 的组合
  - `TIMESTAMP`：功能和 `DATETIME` 相同（但范围较小）
  - `TIME`：格式为 `HH:MM:SS`
  - `YEAR`：用 2 位数字表示，范围是 `70(1970)~69(2069)`；用 4 位数字表示，范围是 `1901~2155`
- 二进制数据类型（例如图像、多媒体、字处理文档等）
  - `TINYBLOB`：最大长度为 255 字节
  - `BLOB`：最大长度为 64KB
  - `MEDIUMBLOB`：最大长度为 16MB
  - `LONGBLOB`：最大长度为 4GB

### Tips
- 内部联结首选 `INNER JOIN` 而不是 `WHERE` 语句
- 用自联结而不用子查询：自联结通常作为外部语句用来替代从相同表中检索数据时使用的子查询语句
- `INSERT UPDATE DELETE` 通常不如 `SELECT` 来的重要，可以通过关键字 `LOW_PRIORITY` 降低执行的优先级：
    - `INSERT LOW_PRIORITY INTO`