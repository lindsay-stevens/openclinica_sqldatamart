:: Setup the environment for creating a throw-away database cluster for this demo.
call postgres\pg_env.bat

:: Avoid password prompts.
@SET PGPASSWORD=password

:: Initdb doesn't accept the above, but we can write it to a file and provide that.
echo %PGPASSWORD%>postgres\.pgpass

:: Flags explained here: https://www.postgresql.org/docs/current/static/app-initdb.html
initdb -D postgres\data -U postgres -A md5 -E UTF-8 --pwfile=postgres\.pgpass

:: Start cluster, create restore database, execute restore.
pg_ctl start -l postgres\mylog.txt
createdb openclinica
pg_restore -d openclinica -O -j 4 juno_study.backup

:: These are setup steps from the "Basic" instructions.
psql -d openclinica -c "CREATE ROLE openclinica_select NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;"
psql -d openclinica -c "GRANT CONNECT ON DATABASE openclinica to openclinica_select;
psql -d openclinica -c "GRANT USAGE ON SCHEMA public to openclinica_select;"
psql -d openclinica -c "GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;"

:: Begin the startup process.
call setup_sqldatamart.bat

:: Write out examples of created objects now being written to CSV files.
psql -d openclinica_fdw_db -c "\copy (SELECT matviewname FROM pg_catalog.pg_matviews WHERE schemaname='the_juno_diabetes_study') TO 'juno_matviews.csv' WITH HEADER CSV"
psql -d openclinica_fdw_db -c "\copy (SELECT * FROM the_juno_diabetes_study.ig_eatin_habits) TO 'item_group_example.csv' WITH HEADER CSV"
psql -d openclinica_fdw_db -c "\copy (SELECT * FROM the_juno_diabetes_study.subjects) TO 'subjects_listing.csv' WITH HEADER CSV"
