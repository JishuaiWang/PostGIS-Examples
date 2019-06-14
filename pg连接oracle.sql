--https://github.com/laurenz/oracle_fdw/releases下载相应版本
--extension/oracle_fdw-2.1.0-pg96-win64.zip

--下载完成将zip包解压，把【lib】文件夹的oracle_fdw.dll和【share/extension】目录下的三个文件分别复制到PostgreSQL安装目录下的【lib】文件夹和【share/extension】目录里去。

-- 创建oracle_fdw
create extension oracle_fdw;

-- 语句能查询到oracle_fdw extension，如下图
select * from pg_available_extensions;
 
--创建访问oracle的连接
create server oracle foreign data wrapper oracle_fdw options(dbserver '10.110.XX.XX:1521/orcl1');

--授予postgres用户访问权限
grant usage on foreign server oracle to postgres;

--创建到oracle的映射
create user mapping for postgres server oracle options(user 'scgx_db',password 'xxxxxx');

--创建需要访问的oracle中对应表的结构
create foreign table "wyzx"."pg_gc_gsm"(
  "date_id" float,
  "date_time" varchar(50),
  "city_name" varchar(50),
  "county_name" varchar(50),
  "cell_name_chs" varchar(500),
  "lac" varchar(50),
  "cgi" varchar(50),
  "station_name" varchar(200),
  "longitude_antenna" varchar(50),
  "latitude_antenna" varchar(50),
) server oracle options(schema 'SCGX_DB',table 'GC_GSM');