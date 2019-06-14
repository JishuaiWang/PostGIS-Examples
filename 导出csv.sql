--从PG导出到CSV
CREATE OR REPLACE FUNCTION export_miscro_week_task() RETURNS int AS $idx$ DECLARE
idx int= 0;
timestr varchar='';
daystr varchar='';
create_table_sql text;
file_path varchar='';
tablename varchar='';
BEGIN
	timestr=to_char(CURRENT_DATE + cast((-1*(TO_NUMBER(to_char(CURRENT_DATE,'D'),'99')-2) - 7) || 'days' as interval),'yyyymmdd');
	daystr=to_char(CURRENT_DATE + cast((-1*(TO_NUMBER(to_char(CURRENT_DATE,'D'),'99')-2) - 7) || 'days' as interval),'yyyy-mm-dd');
	tablename='wyzx.t_miscro_score_week_'||timestr;
	file_path='D:/mssql_pg/miscro/week/t_miscro_score_week_'||timestr||'.csv';
	---------------------------------------------------
    --导出csv
	create_table_sql :='copy (select * from wyzx.pg_microregion_score_w where time='''||daystr||''') to '''||file_path||''' with csv';
	 
	EXECUTE create_table_sql;
	--创建表结构
	EXECUTE 'create table '||tablename||' as (select * from wyzx.pg_microregion_score_w limit 0)';
	---------------------------------------------------
	idx=1;
	---------------------------------------------------
	return idx;
END
$idx$ LANGUAGE plpgsql;