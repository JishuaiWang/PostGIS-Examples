--生成泰森多边形
select st_dump(st_voronoipolygons(geom)) as geom 
from (select st_collect(st_geomfromtext('POINT ('||bbu_longitude||' '||bbu_latitude||')',4326)) as geom from "gc_lte") as g;

--生成泰森多边形并创建新表
create table layerTMP
as with voronio(vor)
as (select st_dump(st_voronoipolygons(geom)) as geom 
from (select st_collect(st_geomfromtext('POINT ('||bbu_longitude||' '||bbu_latitude||')',4326)) as geom from "gc_lte") as g)
select (vor).path,(vor).geom from voronio;

--创建索引，方便查询
create index layertmp_geom_index on layertmp using gist(geom)

--计算每个泰森多边形内包含的点，以及点的属性信息
create table layerRESULT as 
select gc_lte.enodeb,layertmp.geom
from layertmp,gc_lte
where st_contains(layertmp.geom, st_geomfromtext('POINT ('||gc_lte.bbu_longitude||' '||gc_lte.bbu_latitude||')',4326))