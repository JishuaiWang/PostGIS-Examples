--extension/odbcfdw_win64_96_bin.zip

-- 创建odbc_fdw
CREATE EXTENSION odbc_fdw

--创建 server
--** ODBC Driver 17 for SQL Server 需要安装 **
CREATE SERVER sqlserver FOREIGN DATA WRAPPER odbc_fdw OPTIONS (odbc_DRIVER 'ODBC Driver 17 for SQL Server',odbc_SERVER '10.110.XX.XXX',odbc_port '1433');

--给其他用户授予 server 使用权限
GRANT USAGE ON FOREIGN SERVER sqlserver to postgres; 
--建用户和 server 之间的映射关系
CREATE USER MAPPING FOR postgres SERVER sqlserver OPTIONS ( "odbc_UID" 'sa', "odbc_PWD" 'xxxx');

--微区域
create foreign table "wyzx"."pg_microregion_score_d"(	
    "time" date, 
    "a_00" varchar(100), 
	"a_01" varchar(100), 
	"wqy_id" varchar(100), 
	"mr_rate" float, 
	"low_phr_rate" float, 
	"cover_rate" float
) SERVER sqlserver OPTIONS (odbc_DATABASE 'Data_Center',table 'report_microregion_custom_score_d');