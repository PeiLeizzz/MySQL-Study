## MySQL 技术内幕

### MySQL 体系结构和存储引擎
- 数据库：物理操作系统文件或其他形式**文件**类型的集合
- 实例：MySQL 数据库由后台线程以及一个共享内存区组成，共享内存区可以被运行的后台线程所共享，数据库实例才是真正用于操作数据库文件的（**程序**）
- InnoDB 存储引擎
  - **行级锁、支持外键、非锁定读（默认读操作不加锁）**
  - 支持四种隔离级别，默认为 REPEATABLE，使用一种叫 `next-key locking` 策略来避免幻读
  - 提供插入缓冲、二次写、自适应哈希索引、预读
  - 采用聚集索引，每张表的存储都按主键的顺序进行存放
- MyISAM 存储引擎
  - 不支持事务、表级锁、支持全文索引
  - 缓冲池只缓冲索引文件，不缓冲数据文件
- NDB 存储引擎
  - 数据全部存放在内存中（v5.1 之后，可以将非索引文件放在磁盘上）
  - 连接操作在 Server 层完成，而不是存储引擎层
- Memory 存储引擎
  - 表中数据存放在内存中
  - 适合于存储临时表，默认使用哈希索引（而不是 B+ 树）
  - 只支持表锁，变长字段按照定长字段存储

## InnoDB 存储引擎
- InnoDB 体系结构：
  ```mermaid
  graph LR;
  subgraph innodb;
    A(后台线程)-.-B(后台线程);
    B(后台线程)-.-C(后台线程);
    C(后台线程)-.-D(后台线程);
    E[InnoDB 存储引擎内存池];
  end;
  F[文件]-.-G[文件];
  G[文件]-.-H[文件];
  H[文件]-.-I[文件];
  ```
  InnoDB 存储引擎有多个内存块，这些内存块组成了一个大的内存池
  - 维护所有进程/线程需要访问的多个内部数据结构
  - 缓存磁盘上的数据，方便快速地读取，同时在对磁盘文件的数据修改之前在这里缓存
  - 重做日志（redo log）缓冲
  
  后台线程的主要作用是**负责刷新内存池中的数据，保证缓冲池中的内存缓冲的是最近的数据**。此外**将已修改的数据文件刷新到磁盘文件，同时保证在数据库发生异常的情况下 InnoDB 能恢复到正常运行状态**
  
- ==后台线程==
  
  - **Master Thread**：核心线程，主要负责**将缓冲池中的数据异步刷新到磁盘**，保证数据的一致性。包括**脏页的刷新、合并插入缓冲、undo 页的回收**等。
  - IO Thread：负责 IO 请求的回调处理
    - write thread
    - read thread
    - insert buffer thread
    - log IO thread
  - Purge Thread：事务被提交后，其所使用的 undo log 可能不再需要，因此需要该线程来**回收已经使用并分配的 undo 页**
  - Page Cleaner Thread：负责脏页的刷新
  
- ==内存==
  
  ```mermaid
  graph LR;
  A[重做日志缓冲];
  B[额外内存池];
  A-.-B;
  subgraph innodb_buffer_pool;
    C[数据页];
    D[索引页];
    E[插入缓冲];
    F[自适应哈希索引];
    G[锁信息];
    C-.-D;
    E-.-F-.-G;
  end;
  ```
  
  - **缓冲池**：一块内存区域，通过内存的数据来弥补磁盘 IO 的速度。读取时，将页缓存在缓冲池中；修改时，先修改缓冲池中的页，然后再以一定的频率刷新到磁盘上
    
    - 缓冲池中缓存的页类型有：**索引页、数据页、undo 页、插入缓冲、自适应哈希索引、InnoDB 存储的锁信息、数据字典信息**等
    - 缓冲池通过 LRU 算法来管理，页的默认大小为 16KB。LRU 列表中还加入了 midpoint 位置，新读取到的页放入 midpoint 位置而不是首部(midpoint insertion strategy)，防止某些只用一次的页占据了首部的位置
    - 参数 `innodb_old_blocks_time` 限制页被加入到 mid 位置后至少需要多久才能被加入 LRU 的热端
    - InnoDB 1.0.x 版本开始支持压缩页的功能，通过 unzip_LRU 列表对不同压缩页的大小进行分别管理（伙伴算法）
      > 假设需要对缓冲池申请页为 4KB 的大小，过程：
      >
      > 1. 检查 4KB 的 unzip_LRU 列表，检查是否有可用的空闲页；
      > 2. 若有，直接使用；
      > 3. 否则，检查 8KB 的 unzip_LRU 列表
      > 4. 若有，将页分成 2 个 4KB 页，存放到 4KB 的 unzip_LRU 列表
      > 5. 否则，从 LRU 列表中申请一个 16KB 的页，将页分为 1 个 8KB 的页、2 个 4KB 的页，分别存放到对应的 unzip_LRU 列表中
    - 脏页：LRU 列表中被修改后的页，即缓冲池中的页和磁盘上的页数据不一致。这时数据库会通过 CHECKPOINT 机制将脏页刷新回磁盘，而 Flush 列表中的页即为脏页列表（脏页既存在于 LRU 列表中，也存在于 Flush 列表中，LRU 列表用来管理缓冲池中页的可用性，Flush 列表用来管理将页刷新回磁盘）
  - **重做日志缓冲（redo log buffer）**：InnoDB 存储引擎首先将重做日志信息先放入到这个缓冲区，然后按一定频率刷新到重做日志文件（一般每秒刷入，因此用户只要保证这个缓冲区大小大于每秒产生的事务量）。
    
    - 刷新到日志文件的时机
      - Master Thread 每秒将其刷进
      - 每个事务提交时
      - 重做日志缓冲区剩余空间小于 1/2 时
  - **额外的内存池**：在对一些**数据结构本身的内存**进行分配时，需要从额外的内存池中进行申请，当该区域的内存不够时，会从缓冲池中进行申请。
  
- CheckPoint 技术
  - 为避免发生数据丢失的问题，当前事务数据库系统普遍都采用了 Write Ahead Log 策略：即当事务提交时，先写重做日志，再修改页。当由于发生宕机而导致数据丢失时，通过重做日志来完成数据的修复（事务的持久性）
  - CheckPoint 技术的目的：
    - 缩短数据库的恢复时间
    - 缓冲池不够用时，将淘汰的脏页刷新到磁盘
    - 重做日志不可用时，刷新脏页（让缓冲池的页刷新到当前重做日志的位置，以便重做日志的覆盖重用）
  - 当数据库发生宕机时，不用重做所有的日志，因为 CheckPoint 之前的页都已经刷新回磁盘，只需要对 CheckPoint 后的重做日志进行恢复
  - **Sharp Checkpoint**：发生在数据库关闭时将所有的脏页都刷新回磁盘
  - **Fuzzy Checkpoint**：只刷新一部分脏页，包括：
    - **Master Thread Checkpoint**：差不多以每秒或每十秒的速度从缓冲池的脏页列表中刷新一定比例的页回磁盘。这个过程是异步的，即此时 InnoDB 存储引擎可以进行其他的操作，用户查询线程不会阻塞。
    - **FLUSH_LRU_LIST Checkpoint**：需要保证 LRU 列表中有差不多 100 个空闲页可供使用，如果没有，则移除列表尾部的页，如果其中有脏页，则进行 Checkpoint（InnoDB 1.1.x 之前，检查 LRU 列表中是否有足够空间发生在用户查询线程中，会阻塞查询；1.2.x 开始，该检查被放在一个单独的 Page Cleaner 线程中进行）
    - **Async/Sync Flush Checkpoint**：重做日志不可用的情况，此时脏页是从脏页列表(Flush)中选取的（InnoDB 1.2.x 之前，会阻塞用户查询线程；1.2.x 开始，这部分的刷新操作被放入到了单独的 Page Cleaner 线程中进行）
    - **Dirty Page too much**：脏页数量太多，强制进行 Checkpoint
  
- Master Thread 工作方式
  - 1.0.x 之前，内部循环：
    - **主循环**：
      - 每秒一次的操作：
        - 重做日志缓冲刷新到重做日志文件，即使这个事务还没有提交（必须）
        - 合并插入缓冲（可能，前一秒内 IO 次数小于 5 次）
        - 至多刷新 100 个 InnoDB 的缓冲池中的脏页到磁盘（可能，如果脏页过多）
        - 如果当前没有用户活动，则切换到后台循环
      - 十秒一次的操作：
        - 刷新 100 个脏页到磁盘（可能，过去十秒 IO 操作小于 200 次）
        - 合并至多 5 个插入缓冲（总是）
        - 将日志缓冲刷新到磁盘（日志文件）（总是）
        - 删除无用的 undo 页（最多尝试回收 20 个 undo 页），例如真正执行 update、delete（可能之前只是修改了版本号）
        - 刷新 100 个或者 10% 的脏页到磁盘（总是，超过 70%，则 100 个，否则 10%）
    - **后台循环**：当前没有用户活动（数据库空闲）或者数据库关闭时
      - 删除无用的 undo 页（总是）
      - 合并 20 个插入缓冲（总是）
      - 跳回到主循环（总是）
      - 不断刷新 100 个页直到符合条件（可能，跳转到刷新循环中完成）
    - **刷新循环**
      - 切换到暂停循环，将主循环挂起，等待事件的发生
    - **暂停循环**
    ```c
    void master_thread() {
      goto loop;
    loop:
      for (int i = 0; i < 10; i++) {
        thread_sleep(1)
        do log buffer flush to disk
        if (last_one_second_ios < 5) {
          do merge at most 5 insert buffer
        }
        if (buf_get_modified_ratio_pct > innodb_max_dirty_pages_pct) {
          do buffer pool flush 100 dirty pages
        }
        if (no user activity) {
          goto background loop
        }
      }
      if (last_ten_second_ios < 200) {
        do buffer pool flush 100 dirty pages
      } 
      do merge at most 5 insert buffer
      do log buffer flush to disk
      do full purge
      if (buf_get_modified_ratio_pct > 70%) {
        do buffer pool flush 100 dirty pages
      } else {
        buffer pool flush 10% dirty pages
      }
    
      goto loop
    
      background loop:
        do full purge
        do merge 20 insert buffer
        if (!idle) {
          goto loop
        } else {
          goto flush loop
        }
      
      flush loop:
        do buffer pool flush 100 dirty pages
        if (buf_get_modified_ratio_pct > innodb_max_dirty_pages_pct) {
          goto flush loop
        }
        goto suspend loop
      
      suspend loop:
        suspned_thread()
        waiting event
    
      goto loop
    }
    ```
    
  - 1.0.x - 1.2.x 版本：在 1.0.x 之前，最多刷新 100 个脏页、合并 20 个插入缓存等硬编码，已不适合现在的硬件。
    
    - 1.2.x 之前通过参数 `innodb_io_capacity` 来表示磁盘的吞吐量，对于刷新到磁盘页的数量，会按照 `innodb_io_capacity` 的百分比来控制：合并插入缓存为 5%，从缓冲区刷新脏页为 100%
    - 脏页比例阈值 `innodb_max_dirty_pages_cnt` 从 90 改为 75，这样既能加快刷新脏页的频率，又能保证磁盘 IO 的负载
    - 自适应刷新参数 `innodb_adaptive_flushing`，通过判断产生重做日志的速度来决定最合适的刷新脏页数量
    - 通过参数 `innodb_purge_batch_size` 控制回收的 undo 页的数量
    
  - 1.2.x 版本：
    
    ```c
    if (InnoDB is idle) {
      srv_master_do_idle_tasks(); // 10 秒的操作
    } else {
      srv_master_do_active_tasks(); // 每秒的操作
    }
    ```
    同时将刷新脏页的操作单独分配到 Page Cleaner 线程中
  
- ==关键特性==

  - **插入缓冲（Insert Buffer）**：在缓冲池中，与数据页一样，也是物理页的一个组成部分。对于**非聚集索引**的插入或更新操作，不是每一次直接插入到索引页中，而是先判断插入的非聚集索引页是否在缓冲池中，若在，则直接插入；若不在，则先放入到一个 Insert Buffer 对象中，然后再以一定的频率和情况进行 Insert Buffer 和（非聚集的）辅助索引页子节点的合并操作，这时通常能将多个插入合并到一个操作中（因为在一个索引页中）

      需要同时满足两个条件：**索引是非聚集的辅助索引**（如果是聚集索引（主键索引），那么是按顺序插入的，不需要随机访问）；**索引不是唯一的**（因为在插入缓冲时，数据库并不去查找索引页来判断插入的记录的唯一性，如果又去查找则又必然会进行随机读取，导致插入缓冲失去意义。

      - Change Buffer：1.0.x 版本开始引入，可将其视为 Insert Buffer 的升级，它可以使得 DML 操作——Insert、Delete（Delete Buffer）、Update（Purge Buffer） 都进行缓冲。它的对象依然是非唯一的辅助索引。

      - Insert Buffer 内部原理：**所有表共享一棵 Insert Buffer B+ 树，存放在共享表空间中**。

          非叶节点：存放 search key：`|space(4B)|marker(1B)|offset(4B)|`，space 是每个表的 id，marker 用于兼容老版本 Insert Buffer，offset 表示页所在偏移量。

          叶子节点：

          ```
          |space(4B)|marker(1B)|offset(4B)|metadata(4B)|data..|
          																		|
          																		|
          |IBUF_REC_OFFSET_COUNT(用于记录插入顺序)|IBUF_REC_OFFSET_TYPE|IBUF_REC_OFFSET_FLAGS|
          ```

          Insert Buffer Bitmap：一个特殊的页，用于标记每个辅助索引页的可用空间，每个辅助索引页在其中占用 4 bit

          ```c
          IBUF_BITMAP_FREE(2b) // 表示可用空间数量 
          IBUF_BITMAP_BUFFERED(1b) // 表示该辅助索引页有记录被缓存在 Insert Buffer B+ 树中
          IBUF_BITMAP_IBUF(1b) // 表示该页为 Insert Buffer B+ 树的索引页
          ```

      - Merge Insert Buffer：

          操作发生的节点：

          - 辅助索引页被读取到缓冲池时；
          - Insert Buffer Bitmap 页追踪到该辅助索引页已无可用空间时；
          - Master Thread：随机选择 Insert Buffer B+ 树的一个页，读取该页中的 space 及之后所需要数量的页（该算法在复杂情况下有更好的公平性）

  - **两次写（Double Write）**：内存中有 doublewrite buffer（2MB），物理磁盘上共享表空间中有 2 个区（2MB）的 doublewrite。

      - 缓冲池刷新脏页时，将脏页复制到 doublewrite buffer 中（而不是直接写入磁盘）
      - 之后通过 doublewrite buffer 再分两次，每次 1MB 顺序地写入 doublewrite，然后马上调用 fsync 函数，同步磁盘，避免缓冲写带来的问题
      - 完成 doublewrite 页的写入后，再将 doublewrite buffer 中的页离散地写入各个表空间文件中

      ```mermaid
      graph LR;
      subgraph memory;
      	A[page]-.copy.->B[doublewrite buffer 2MB];
      	C[page]-.copy.->B;
      end;
      subgraph shared_table;
      	D[doublewrite 1MB]-.-E[doublewrite 1MB]
      end;
      B-.write.->D
      B-.write.->F
      subgraph data;
      F(data)-.-G(data)-.-H(data)
      end;
      E-.recovery.->F
      ```

      - 好处在于写入磁盘崩溃时，可以通过共享表空间中的 doublewrite 副本恢复

  - **自适应哈希索引（Adaptive Hash Index）**：InnoDB 存储引擎会监控对表上各索引页的查询，如果观察到建立哈希索引可以带来速度提升，则建立哈希索引。其通过缓冲池的 B+ 树页构造而来，建立速度很快，不需要对整张表构建哈希索引。InnoDB 会自动根据访问的频率和模式自动地为某些热点页建立哈希索引。

      - 要求：对这个页的连续访问模式（查询条件）必须一样；以该模式访问了 100 次；页通过该模式访问了 N 次，其中 N = 页中记录 * 1/16
      - 哈希索引只能用来搜索**等值查询**

  - 异步 IO（Async IO）

      - 用户可以在发送一个 IO 请求后立即发送另一个，当全部 IO 请求发送完毕后，等待所有 IO 操作的完成
      - 另一个优势是可以进行 IO Merge 操作，将多个 IO 合并为一个

  - 刷新邻接页（Flush Neighbor Page）：当刷新一个脏页时，InnoDB 会检测该页所在区的所有页，如果是脏页，则一起刷新（可以结合 AIO 将多个 IO 写入操作合并为一个）