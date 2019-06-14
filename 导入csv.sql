--导入CSV到PG
CREATE OR REPLACE FUNCTION import_miscro_week_task() RETURNS int AS $idx$ DECLARE
idx int= 0;
timestr varchar='';
daystr varchar='';
create_table_sql text;
create_index_sql text;
file_path varchar='';
tablename varchar='';
BEGIN
	timestr=to_char(CURRENT_DATE + cast((-1*(TO_NUMBER(to_char(CURRENT_DATE,'D'),'99')-2) - 7) || 'days' as interval),'yyyymmdd');
	daystr=to_char(CURRENT_DATE + cast((-1*(TO_NUMBER(to_char(CURRENT_DATE,'D'),'99')-2) - 7) || 'days' as interval),'yyyy-mm-dd');
	tablename='wyzx.t_miscro_score_week_'||timestr;
	file_path='D:/mssql_pg/miscro/week/t_miscro_score_week_'||timestr||'.csv';
	---------------------------------------------------
    --建表，导入数据
	create_table_sql :='copy '||tablename||' from '''||file_path||''' with csv';
	EXECUTE create_table_sql;
	
    EXECUTE 'select AddGeometryColumn(''wyzx'',''t_miscro_score_week_'||timestr||''',''geom'',4326,''MULTIPOLYGON'',2)';
	
	EXECUTE 'update '||tablename||' t set geom=(select geom from wyzx.t_miscro_region where code=t.wqy_id)';
	---------------------------------------------------
    --创建索引
	create_index_sql:='create index t_miscro_score_week_'||timestr||'_geom_idx on '||tablename||' using gist(geom)';
	EXECUTE create_index_sql;
    --写入日志表
	EXECUTE 'insert into wyzx.importlog(type,cycle,time) values(''miscro_score_week_server'',''week'','''||daystr||''')';
	idx=1;
	---------------------------------------------------
	return idx;
END
$idx$ LANGUAGE plpgsql;