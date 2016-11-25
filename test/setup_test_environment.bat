:: Set environment variables for the testing server.
call %~dp0pg_env.bat
@echo off

:: Which fixture database to use, and it's location.
@set fixture_database=juno
@set backup_file_path=%~dp0fixtures\%fixture_database%.backup

@set setup_start_time=%time%

@echo Initialising database cluster, deleting any previous copy...
pg_ctl stop
rmdir %pg_data% /s /q
mkdir %pg_data%
:: Won't accept PGPASSWORD but can be given a file containing the password.
initdb -D %pg_data% -U postgres -A md5 -E UTF-8 --pwfile=%~dp0.pgpass
pg_ctl start -w -l %pg_data%\test_log.txt

@echo Loading test OpenClinica database and running prep script...
:: Flags: no password prompt, create objects, don't load owner or ACL info.
pg_restore -w -C -O -x -d postgres %backup_file_path%
@set pg_database_old=%PGDATABASE%
@set PGDATABASE=openclinica
psql -q -P pager                                                               ^
     -f %~dp0..\scripts\build\openclinica_db_prep.sql                          ^
     -f %~dp0..\scripts\build\datamart_db_configs.sql
@set PGDATABASE=%pg_database_old%

@echo.
@echo Environment setup start: %setup_start_time%
@echo Environment setup end:   %time%
@echo.
