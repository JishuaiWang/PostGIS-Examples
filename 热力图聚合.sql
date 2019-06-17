drop table tbl_pos;
--create table
create table tbl_pos(  
  id int,    
  info text,   -- 信息  
  val float8,  -- 取值  
  pos point    -- 位置  
);  

--随机插入数据
insert into tbl_pos
select generate_series(1,1000000),md5(random()::text), random()*1000, point((97+random()*(108-97)), (26+random()*(34-26)));

select * from tbl_pos;

--强制并行计算
set min_parallel_table_scan_size =0;
set min_parallel_index_scan_size =0; 
set parallel_setup_cost =0; 
set parallel_tuple_cost =0; 
set max_parallel_workers_per_gather =28;
alter table tbl_pos set (parallel_workers =28); 

--热力图聚会
select   
  width_bucket(pos[0], 97, 108, 50),  -- x轴落在哪列bucket  
  width_bucket(pos[1], 26, 34, 50),  -- y轴落在哪列bucket  
  avg(val),  min(val),  max(val),  stddev(val), count(*)  
from tbl_pos group by 1,2;
--width_bucket(  
--  p1 -- 输入值  
--  p2 -- 边界值（最小，包含）  
--  p3 -- 边界值（最大，不包含）  
--  p4 -- 切割份数  
--) 

--前端渲染