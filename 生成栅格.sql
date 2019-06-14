--生成栅格

--新建表
create table raster(
    objectid varchar(255),
    wkt varchar(255),
    x float,
    y float
);
--添加geom字段
select AddGeometryColumn('wyzx','raster','geom',3857,'POLYGON',2);

--生成栅格函数
CREATE OR REPLACE FUNCTION createRaster() RETURNS int AS $idx$ DECLARE
idx int= 0;
minx float=10835768;--左下角点x
miny float=3004652;--左下角点y
DECLARE i int;
DECLARE j int;
wkt VARCHAR;
BEGIN
	for i in 0..2496 loop--2496
		for j in 0..2134 loop--2134
			wkt='POLYGON(('||(minx+i*500)||' '||(miny+j*500)||','||(minx+(i+1)*500)||' '||(miny+j*500)||','||(minx+(i+1)*500)||' '||(miny+(j+1)*500)||','||(minx+i*500)||' '||(miny+(j+1)*500)||','||(minx+i*500)||' '||(miny+j*500)||'))';
			INSERT INTO raster values(cast(i as varchar)||'-'||cast(j as varchar),wkt,minx+i*500+250,miny+j*500+250,st_geomfromtext(wkt,3857));
			idx=idx+1;
		end loop;
	end loop;
	return idx;
END
$idx$ LANGUAGE plpgsql;

--裁剪栅格
select a.objectid,ST_Intersection(b.geom,a.geom) as geom,'1' from raster a, t_gis_base_city_3857 b where b.objectid=1;