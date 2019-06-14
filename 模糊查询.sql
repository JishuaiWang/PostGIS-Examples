show maintenance_work_mem ;  
set maintenance_work_mem = '1GB'; 

-----------------------前、后模糊的合体优化方法-----------------------
--使用扩展插件
create extension pg_trgm;
--创建测试表
create table test001(c1 text);
--生成随机中文字符串的函数
create or replace function gen_hanzi(int) returns text as $$                  
declare        
  res text;        
begin        
  if $1 >=1 then        
    select string_agg(chr(19968+(random()*20901)::int), '') into res from generate_series(1,$1);        
    return res;        
  end if;        
  return null;        
end;        
$$ language plpgsql strict;
--插入测试数据
insert into test001 select gen_hanzi(20) from generate_series(1,100000); 
--创建索引
create index idx_test001_1 on test001 using gin (c1 gin_trgm_ops);

select * from test001 limit 5;
--查询测试
--(有前缀的模糊)至少输入1个字符，(有后缀的模糊)至少输入2个字符，才有好的索引过滤效果。
explain (analyze,verbose,timing,costs,buffers) select * from test001 where c1 like '你%';  
explain (analyze,verbose,timing,costs,buffers) select * from test001 where c1 like '%髓篺';   


-----------------------前后均模糊的优化-----------------------
--建议输入3个或3个以上字符，否则效果不佳
explain (analyze,verbose,timing,costs,buffers) select * from test001 where c1 like '%燋邢賀%'; 


-----------------------小于3个输入字符的模糊查询的优化-----------------------
create or replace function split001(text) returns text[] as $$      
declare      
  res text[];      
begin      
  select regexp_split_to_array($1,'') into res;      
  for i in 1..length($1)-1 loop      
    res := array_append(res, substring($1,i,2));      
  end loop;      
  return res;      
end;      
$$ language plpgsql strict immutable;
--创建索引
create index idx_test001_2 on test001 using gin (split001(c1));
--查询测试
explain (analyze,verbose,timing,costs,buffers) select * from test001 where split001(c1) @> array['你你'];

select * from test001 where split001(c1) @> array['篺'];


-----------------------相似查询优化-----------------------
create index idx_test001_3 on test001 using gist (c1 gist_trgm_ops);
--查询测试
explain (analyze,verbose,timing,costs,buffers) SELECT t, c1 <-> '擁乙媔硓髓篺你贒帯蒯泀煩瓊飌睍涊' AS dist        
  FROM test001 t        
  ORDER BY dist LIMIT 5;


-----------------------性能测试-----------------------
insert into test001 select gen_hanzi(15) from generate_series(1,2500000);

set maintenance_work_mem ='2GB';

create index idx_test001_1 on test001 using gin (c1 gin_trgm_ops); 

select * from test001 where c1 like '你%';

explain (analyze,verbose,timing,costs,buffers) 

select * from test001 where c1 like '%悶騴恓廙%';

------------------------实战----------------------------------
drop index name_index_1;
drop index name_index_2;
drop index name_index_3;
--三个字符最佳
create index name_index_1 on "建筑物区域" using gin (name gin_trgm_ops);
select * from "建筑物区域" where name like '%社区B-13-2地块10号楼%';
--小于三个字符最佳
create index name_index_2 on "建筑物区域" using gin (split001(name));
select * from "建筑物区域" where split001(name) @> array['地块'];
--相似匹配最佳
create index name_index_3 on "建筑物区域" using gist (name gist_trgm_ops);
SELECT t.name, name <-> '青城144号1栋' AS dist        
  FROM "建筑物区域" t        
  ORDER BY dist LIMIT 5;
SELECT t.name, name <-> '青' AS dist        
  FROM "建筑物区域" t        
  ORDER BY dist LIMIT 5;
