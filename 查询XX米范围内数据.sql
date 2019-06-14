--新增字段
select AddGeometryColumn('GC_LTE_20181022','geom',4326,'POINT',2);
--构造geometry
update "GC_LTE_20181022" set geom=st_geomfromtext('POINT ('||"BBU_LONGITUDE"||' '||"BBU_LATITUDE"||')',4326) where "BBU_LONGITUDE" !='' and "BBU_LATITUDE"!=''
--创建索引
create index GC_LTE_20181022_geom_idx on "GC_LTE_20181022" using gist(geom);
--聚合查询-50米
 create table gc_let_result_50 as select a."CGI" as acgi,b."CGI" as bcgi,
 case  when a."ANGLE_LOCATION" !='' and b."ANGLE_LOCATION" !='' then  cast(a."ANGLE_LOCATION" as FLOAT)-cast(b."ANGLE_LOCATION" as FLOAT)
 else null end as angle from
(select * from "GC_LTE_20181022") a,
(select * from "GC_LTE_20181022") b
where ST_DWithin(a.geom,b.geom,0.05/111.325)=true and a.geom is not null and b.geom is not null and a."CGI"!=b."CGI" 
--聚合查询-300米
 create table gc_let_result_300 as select a."CGI" as acgi,b."CGI" as bcgi,
 case  when a."ANGLE_LOCATION" !='' and b."ANGLE_LOCATION" !='' then  cast(a."ANGLE_LOCATION" as FLOAT)-cast(b."ANGLE_LOCATION" as FLOAT)
 else null end as angle from
(select * from "GC_LTE_20181022") a,
(select * from "GC_LTE_20181022") b
where ST_DWithin(a.geom,b.geom,0.3/111.325)=true and a.geom is not null and b.geom is not null and a."CGI"!=b."CGI" 
