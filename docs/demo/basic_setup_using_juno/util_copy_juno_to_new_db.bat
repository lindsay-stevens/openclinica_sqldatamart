:: Variables.
@SET target_schema_name=the_juno_diabetes_study
@SET export_views_in_schema=TRUE
@SET target_schema_name_alias=%target_schema_name%_t

:: Ensure the process is possible: (re)start the server, clear connections.
call %~dp0util_restart.bat
@SET pg_database_old=%PGDATABASE%
@SET PGDATABASE=openclinica_fdw_db

:: To prepare for export, copy the tables and views from the schema as tables.
psql -f %~dp0util_dm_copy_schema_to_tables_for_export.sql
psql -c "SELECT openclinica_fdw.dm_copy_schema_to_tables_for_export($s$%target_schema_name%$s$);" -P pager

:: Export the schema copy containing the tables then remove it.
pg_dump -w -O -x -F c -f %~dp0%target_schema_name%.backup -n %target_schema_name_alias%
psql -c "DROP SCHEMA %target_schema_name_alias% CASCADE;" -P pager
psql -c "DROP FUNCTION openclinica_fdw.dm_copy_schema_to_tables_for_export(text, text, boolean);" -P pager

:: Load / re-dump the exported schema in a new database, using the original schema name.
dropdb --if-exists %target_schema_name%
createdb %target_schema_name%

@SET PGDATABASE=%target_schema_name%
pg_restore -d %target_schema_name%  %~dp0%target_schema_name%.backup
psql -c "ALTER SCHEMA %target_schema_name_alias% RENAME TO %target_schema_name%"  -P pager
pg_dump -w -O -x -F c -f %~dp0%target_schema_name%.backup -n %target_schema_name%
@SET PGDATABASE=%pg_database_old%

echo.
echo Connect to the new database with: psql -d %target_schema_name%
echo Or close this window to finish.
echo.
