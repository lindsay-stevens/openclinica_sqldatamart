:: Assuming the database was previously created, (re)start it.
call %~dp0postgres\pg_env.bat

pg_ctl stop
pg_ctl start -w -l postgres\mylog.txt
