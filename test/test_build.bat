call %~dp0pg_env.bat

@echo.
@echo Initialising database cluster, deleting previous copy if it exists, at:
@echo   %pg_data%
@echo.

rmdir %pg_data% /s /q
mkdir %pg_data%
:: Doesn't accept PGPASSWORD but can be given a file containing the password.
initdb -D %pg_data% -U postgres -A md5 -E UTF-8 --pwfile=%~dp0.pgpass

@echo.
@echo Finished initialising database cluster.
@echo.
@echo Starting up and loading JUNO database into the cluster.
@echo.

pg_ctl start -w -l %pg_data%\test_log.txt
psql -d postgres -c "DROP DATABASE IF EXISTS openclinica;"
psql -d postgres -c "CREATE DATABASE openclinica;"
psql -d openclinica -f %~dp0demo_dbs\juno_openclinica.backup

@echo.
@echo Finished loading JUNO.
@echo.
@echo Building DataMart database.
@echo.

:: These are setup steps from the "Basic" instructions.
@SET pg_database_old=%PGDATABASE%
@SET PGDATABASE=openclinica
psql -c "CREATE ROLE openclinica_select NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;"
psql -c "GRANT CONNECT ON DATABASE openclinica to openclinica_select;
psql -c "GRANT USAGE ON SCHEMA public to openclinica_select;"
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;"
@SET PGDATABASE=%pg_database_old%
call setup_sqldatamart.bat

@echo.
@echo Finished building DataMart.
@echo.
@echo Exporting JUNO schema to a backup file for diffing.
@echo.

:: Copies the tables and views from the schema as tables.
@SET target_schema_name=the_juno_diabetes_study
@SET export_views_in_schema=TRUE
@SET target_schema_name_alias=%target_schema_name%_t
@SET export_func=openclinica_fdw.dm_copy_schema_to_tables_for_export
@SET test_output_path=%~dp0test_output
@SET export_file_path=%test_output_path%\%target_schema_name%.backup
@SET pg_database_old=%PGDATABASE%
@SET PGDATABASE=openclinica_fdw_db

rmdir %test_output_path% /s /q
mkdir %test_output_path%

psql -f %~dp0util_dm_copy_schema_to_tables_for_export.sql
psql -c "SELECT %export_func%($s$%target_schema_name%$s$);" -P pager
pg_dump -w -O -x -F c -f %export_file_path% -n %target_schema_name_alias%
psql -c "DROP SCHEMA %target_schema_name_alias% CASCADE;" -P pager
psql -c "DROP FUNCTION %export_func%(text, text, boolean);" -P pager
psql -d postgres -c "DROP DATABASE IF EXISTS %target_schema_name%;"
psql -d postgres -c "CREATE DATABASE %target_schema_name%;"

@SET PGDATABASE=%target_schema_name%
pg_restore -d %target_schema_name% %export_file_path%
psql -c "ALTER SCHEMA %target_schema_name_alias% RENAME TO %target_schema_name%" -P pager
pg_dump -w -O -x -F p -f %export_file_path% -n %target_schema_name%
@SET PGDATABASE=%pg_database_old%
psql -d postgres -c "DROP DATABASE IF EXISTS %target_schema_name%;"

@echo.
@echo While this console is open, the server will be running at %PGHOST% %PGPORT%
@echo.
@echo Connect with: call pg_env.bat ^& psql -d openclinica_fdw_db
@echo - List JUNO matviews: \pset pager off \dm the_juno_diabetes_study.*
@echo - Or use the kdiff script to inspect differences.
@echo - View PostgreSQL log file at: %pg_data%\test_log.txt
@echo.

pause