--让数据库支持PostGIS和pgRouting的函数和基础表（安装后第一次使用时执行，以后都不再执行）
CREATE EXTENSION postgis;
CREATE EXTENSION pgrouting;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
CREATE EXTENSION address_standardizer; 

--注：使用postgis shapefile mport/export manager上传shp时，在Option中勾选“generate simple geometries instead of multi geometries”，以生成单个geometry

-----------------------------------------
--以节点为参数进行最短路径分析
--以road表作为实例--
-----------------------------------------
ALTER TABLE road ADD COLUMN source integer;--起点 
ALTER TABLE road ADD COLUMN target integer;--终点
ALTER TABLE road ADD COLUMN length double precision;--增加路线长度字段（根据长度设置权重）
UPDATE road SET length = ST_Length(geom);--计算路线长度


select pgr_createTopology('road', 0.0001, 'geom', 'gid');--创建拓扑


SELECT * FROM pgr_dijkstra('SELECT gid as id,
source::integer,target::integer,length::double precision as cost 
FROM road',30, 60, false, false); --路径分析


SELECT st_astext(geom) FROM pgr_dijkstra('SELECT gid AS id,source::integer,
target::integer,length::double precision AS cost FROM road',30, 60, false, false) as di
join road pt on di.id2 = pt.gid;--查询所经过的所有点


SELECT seq, id1 AS node, id2 AS edge, cost,geom into dijkstra_res FROM pgr_dijkstra('
SELECT gid AS id,source::integer,target::integer,length::double precision AS cost FROM road',
30, 60, false, false) as di join road pt on di.id2 = pt.gid;--查询结果存储到新的表格

select * from dijkstra_res;--查询表格内容

-----------------------------------------
--以起始点坐标为参数进行最短路径分析
--以gyroad表作为实例--
-----------------------------------------
ALTER TABLE gyroad ADD COLUMN source integer;--起点 
ALTER TABLE gyroad ADD COLUMN target integer;--终点
ALTER TABLE gyroad ADD COLUMN length double precision;--增加路线长度字段（根据长度设置权重）
UPDATE gyroad SET length = ST_Length(geom);--计算路线长度
select pgr_createTopology('gyroad', 0.0001, 'geom', 'gid');--创建拓扑

--添加起始点坐标x,y字段
ALTER TABLE gyroad ADD COLUMN x1 double precision;
ALTER TABLE gyroad ADD COLUMN y1 double precision;
ALTER TABLE gyroad ADD COLUMN x2 double precision;
ALTER TABLE gyroad ADD COLUMN y2 double precision;
--计算起始点坐标
UPDATE gyroad SET x1 =ST_x(ST_PointN(geom, 1));
UPDATE gyroad SET y1 =ST_y(ST_PointN(geom, 1));
UPDATE gyroad SET x2 =ST_x(ST_PointN(geom, ST_NumPoints(geom)));
UPDATE gyroad SET y2 =ST_y(ST_PointN(geom, ST_NumPoints(geom)));

SELECT seq, id1 AS node, id2 AS edge, cost FROM pgr_astar('SELECT gid AS id,
source::integer,target::integer,length::double precision AS cost,
x1, y1, x2, y2 FROM gyroad',30, 60, false,false);--A*算法路径查询

SELECT seq, id1 AS source, id2 AS target,cost FROM pgr_kdijkstraCost('SELECT gid AS id,
source::integer,target::integer,length::double precision AS cost FROM gyroad',30, 
array[60,70,100], false, false);--查询从出发点到目的地的消耗

SELECT seq, id1 AS path, id2 AS edge, cost FROM pgr_kdijkstraPath('SELECT gid AS id,
source::integer,target::integer,length::double precision AS cost
FROM gyroad',30, array[60,100], false, false);--pgr_kdijkstraPath函数路径分析

-----------------------------------------
--DROP FUNCTION pgr_fromAtoB(varchar, double precision, double precision, 
--                           double precision, double precision);
--基于任意两点之间的最短路径分析
CREATE OR REPLACE FUNCTION pgr_fromAtoB(
                IN tbl varchar,--数据库表名
                IN x1 double precision,--起点x坐标
                IN y1 double precision,--起点y坐标
                IN x2 double precision,--终点x坐标
                IN y2 double precision,--终点y坐标
                OUT seq integer,--道路序号
                OUT gid integer,
                OUT name text,--道路名
                OUT heading double precision,
                OUT cost double precision,--消耗
                OUT geom geometry--道路几何集合
        )
        RETURNS SETOF record AS
$BODY$
DECLARE
        sql     text;
        rec     record;
        source    integer;
        target    integer;
        point    integer;
        
BEGIN
    -- 查询距离出发点最近的道路节点
    EXECUTE 'SELECT id::integer FROM '|| quote_ident(tbl) ||'_vertices_pgr 
            ORDER BY the_geom <-> ST_GeometryFromText(''POINT(' 
            || x1 || ' ' || y1 || ')'',4326) LIMIT 1' INTO rec;
    source := rec.id;
    
    -- 查询距离目的地最近的道路节点
    EXECUTE 'SELECT id::integer FROM '|| quote_ident(tbl) ||'_vertices_pgr 
            ORDER BY the_geom <-> ST_GeometryFromText(''POINT(' 
            || x2 || ' ' || y2 || ')'',4326) LIMIT 1' INTO rec;
    target := rec.id;

    -- 最短路径查询 
        seq := 0;
        sql := 'SELECT gid, geom, name, cost, source, target, 
                ST_Reverse(geom) AS flip_geom FROM ' ||
                        'pgr_bdAstar(''SELECT gid as id, source::int, target::int, '
                                        || 'length::float AS cost,x1,y1,x2,y2 FROM '
                                        || quote_ident(tbl) || ''', '
                                        || source || ', ' || target 
                                        || ' ,false, false), '
                                || quote_ident(tbl) || ' WHERE id2 = gid ORDER BY seq';


    -- Remember start point
        point := source;

        FOR rec IN EXECUTE sql
        LOOP
        -- Flip geometry (if required)
        IF ( point != rec.source ) THEN
            rec.geom := rec.flip_geom;
            point := rec.source;
        ELSE
            point := rec.target;
        END IF;

        -- Calculate heading (simplified)
        EXECUTE 'SELECT degrees( ST_Azimuth( 
                ST_StartPoint(''' || rec.geom::text || '''),
                ST_EndPoint(''' || rec.geom::text || ''') ) )' 
            INTO heading;

        -- Return record
                seq     := seq + 1;
                gid     := rec.gid;
                name    := rec.name;
                cost    := rec.cost;
                geom    := rec.geom;
                RETURN NEXT;
        END LOOP;
        RETURN;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE STRICT;
-----------------------------------------
--测试
SELECT st_astext(ST_MakeLine(route.geom)) FROM (SELECT seq,gid,name,heading,cost,geom FROM pgr_fromAtoB('gyroad', 106.535, 26.905, 106.955, 27.040)ORDER BY seq) AS route
--Openlayers测试
--http://localhost:6060/geoserver/PostGIS/wms?service=WMS&version=1.1.0&request=GetMap&layers=PostGIS:shortgyroad&styles=&bbox=104,24,108,28&width=330&height=768&srs=EPSG:4326&format=application/openlayers&viewparams=x1:106.565;y1:26.915;x2:106.925;y2:28.040