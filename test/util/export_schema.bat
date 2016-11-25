call %~dp0pg_env.bat

@echo.
@echo Exporting schema to a backup file for diffing.
@echo.

:: Copies the tables and views from the schema as tables.
@SET target_schema_name=the_juno_diabetes_study
@SET export_views_in_schema=TRUE
@SET target_schema_name_alias=%target_schema_name%_t
@SET export_func=public.dm_copy_schema_to_tables_for_export
@SET test_output_path=%~dp0test_output
@SET export_file_path=%test_output_path%\%target_schema_name%.backup
@SET pg_database_old=%PGDATABASE%
@SET PGDATABASE=openclinica_fdw_db

if not exist %test_output_path% mkdir %test_output_path%
if exist %export_file_path% del /F /Q %export_file_path%

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
@echo Export complete.
@echo.