:: Assuming the database was previously created, (re)start it.
call %~dp0pg_env.bat

pg_ctl stop
pg_ctl start -w -l %pg_data%\test_log.txt
