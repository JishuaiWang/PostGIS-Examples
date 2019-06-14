--计算点所在区域
create table gc_lte_in_raster_ as
select g.cgi,t.objectid as gridid,t.cityname,t.gridid as num from gc_lte_0527 g
left join t_raster t on ST_Contains(t.geom,g.geom)='t';

--也可以使用存储过程
CREATE OR REPLACE FUNCTION queryLTEInRaster() RETURNS int AS $idx$ DECLARE
idx int= 1;
r record;
BEGIN
	for r in select cgi,geom from gc_lte_0527
	loop 
		insert into gc_lte_in_raster(cgi,objectid,gridid,cityname)
		select r.cgi,objectid,gridid,cityname from t_raster where gridid=floor((st_x(st_astext(r.geom))-10835768)/500)||'-'||floor((st_y(st_astext(r.geom))-3004652)/500) and  ST_Contains(geom,r.geom)='t';
		idx=idx+1;
	end loop;
	return idx;
END
$idx$ LANGUAGE plpgsql;