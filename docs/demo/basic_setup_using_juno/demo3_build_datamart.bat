:: Preparation and variables
call %~dp0postgres\pg_env.bat
call %~dp0util_restart.bat
@SET pg_database_old=%PGDATABASE%

:: These are setup steps from the "Basic" instructions.
@SET PGDATABASE=openclinica
psql -c "CREATE ROLE openclinica_select NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;"
psql -c "GRANT CONNECT ON DATABASE openclinica to openclinica_select;
psql -c "GRANT USAGE ON SCHEMA public to openclinica_select;"
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;"
@SET PGDATABASE=%pg_database_old%

:: Begin the startup process.
call setup_sqldatamart.bat

:: Write out examples of created objects now being written to CSV files.
@SET PGDATABASE=openclinica_fdw_db
psql -c "COPY (SELECT matviewname FROM pg_catalog.pg_matviews WHERE schemaname='the_juno_diabetes_study') TO '%~dp0juno_matviews.csv' WITH HEADER CSV"
psql -c "COPY (SELECT * FROM the_juno_diabetes_study.ig_eatin_habits) TO '%~dp0item_group_example.csv' WITH HEADER CSV"
psql -c "COPY (SELECT * FROM the_juno_diabetes_study.subjects) TO '%~dp0subjects_listing.csv' WITH HEADER CSV"
@SET PGDATABASE=%pg_database_old%

echo.
echo Finished step 3. This window can be closed.
echo To keep the database running, leave this window open.
echo.
