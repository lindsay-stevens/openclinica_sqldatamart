:: Start up the demo PostgreSQL database cluster, assuming it was created previously.
call postgres\pg_env.bat
@SET PGPASSWORD=password
echo %PGPASSWORD%>postgres\.pgpass
pg_ctl start -l postgres\mylog.txt
