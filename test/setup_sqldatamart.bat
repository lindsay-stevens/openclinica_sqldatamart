:: Runs the build process for DataMart.
:: The commands here use psql instead of being in an SQL script because either
:: they must be done in separate transactions (e.g. create database), or
:: because the script must be created in a specific order (e.g. dm schema).

:: Set environment variables for the testing server.
call %~dp0pg_env.bat
@echo off

:: Stop, clear the log file and start.
@echo Restarting PostgreSQL to clear log file...
pg_ctl stop
del %pg_data%\test_log.txt
pg_ctl start -w -l %pg_data%\test_log.txt

@set start_time=%time%
@set "scripts_path=%~dp0..\scripts"

@echo Creating new openclinica_fdw_db, clearing the old one if present...
@set PGDATABASE=postgres
psql -q -P pager                                                               ^
  -c "DROP DATABASE IF EXISTS openclinica_fdw_db;"                             ^
  -c "DROP ROLE IF EXISTS dm_admin;"                                           ^
  -c "CREATE DATABASE openclinica_fdw_db;"

@echo Setting up foreign schema and loading functions...
@set PGDATABASE=openclinica_fdw_db
psql -q -P pager                                                               ^
  -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"                            ^
  -c "CREATE SCHEMA openclinica_fdw;"                                          ^
  -f "%scripts_path%"\build\openclinica_fdw_setup.sql                          ^
  -f %~dp0setup_parameters.sql

for /r "%scripts_path%" %%F in (dm*.sql) do (psql -q -f %%F)

@echo Turning on all logging for debug...
psql -q -P pager                                                               ^
  -c "ALTER DATABASE openclinica_fdw_db SET log_statement TO 'all';"           ^
  -c "ALTER DATABASE openclinica_fdw_db SET log_duration TO 'on';"             ^
  -c "ALTER DATABASE openclinica_fdw_db SET log_min_messages TO 'NOTICE';"

:: These are in a specific order due to query inter-dependencies.
@echo Setting up DataMart objects...
psql -q -P pager                                                               ^
  -c "SELECT openclinica_fdw.set_role_to_database_owner();"                    ^
  -f "%scripts_path%"\dm\mv_dm_metadata_study.sql                              ^
  -f "%scripts_path%"\dm\mv_dm_metadata_study_indexes.sql                      ^
  -f "%scripts_path%"\dm\mv_dm_metadata_site.sql                               ^
  -f "%scripts_path%"\dm\mv_dm_metadata_site_indexes.sql                       ^
  -f "%scripts_path%"\dm\mv_dm_response_sets.sql                               ^
  -f "%scripts_path%"\dm\mv_dm_response_sets_indexes.sql                       ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_meta_mpv.sql                           ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_meta_mpv_indexes.sql                   ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_meta_mv_exp.sql                        ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_meta_mv_exp_indexes.sql                ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_metadata.sql                           ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_metadata_indexes.sql                   ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_item_identifiers.sql                   ^
  -f "%scripts_path%"\dm\mv_dm_study_ig_item_identifiers_indexes.sql           ^
  -f "%scripts_path%"\dm\v_dm_study_ig_viewdefs.sql                            ^
  -f "%scripts_path%"\dm\v_dm_study_ig_clinicaldata_multi_split.sql            ^
  -f "%scripts_path%"\dm\v_dm_study_ig_clinicaldata_multi_reagg.sql            ^
  -f "%scripts_path%"\dm\v_dm_study_ig_clinicaldata.sql
::  -f "%scripts_path%"\dm\v_dm_study_id_ident_rejoin.sql
::  -f "%scripts_path%"\utils\mv_dm_snapshot_code_stata_cmds.sql
::  -f "%scripts_path%"\dm\mv_dm_metadata_pre_view.sql                           ^
::  -f "%scripts_path%"\dm\mv_dm_metadata_mv_exp.sql                             ^
::  -c "SET seq_page_cost = 0.25;"                                               ^
::  -f "%scripts_path%"\dm\mv_dm_metadata.sql                                    ^
::  -c "RESET seq_page_cost;"                                                    ^
::  -f "%scripts_path%"\dm\v_dm_clinicaldata.sql                                 ^
::  -f "%scripts_path%"\dm\v_dm_discrepancy_notes_all.sql
::  -f "%scripts_path%"\build\build_dm_schema.sql

@echo Setting up study schema objects...
psql -q -P pager                                                               ^
  -c "SELECT openclinica_fdw.set_role_to_database_owner();"                    ^
  -c "SELECT openclinica_fdw.dm_create_study_schemas();"                       ^
  -c "SELECT openclinica_fdw.create_study_itemgroup_matviews();"               ^
  -c "SELECT openclinica_fdw.create_study_itemgroup_matviews(TRUE);"

::psql -c "SELECT openclinica_fdw.dm_reassign_owner_study_matviews();"
::psql -c "SELECT openclinica_fdw.dm_create_study_common_matviews();"

:: :: Create views for database maintenance tasks.
:: psql -f "%scripts_path%"\maintenance\refresh_matviews_oc_fdw.sql
:: psql -f "%scripts_path%"\maintenance\refresh_matviews_dm.sql
:: psql -f "%scripts_path%"\maintenance\refresh_matviews_study.sql
:: psql -f "%scripts_path%"\maintenance\user_management_functions.sql
::
:: :: Create per-study database roles.
:: psql -c "SELECT dm_create_study_roles();"
:: psql -c "SELECT dm_grant_study_schema_access_to_study_role();"
:: psql -c "SELECT * FROM dm.user_management_functions;"

@echo.
@echo DataMart build start: %start_time%
@echo DataMart build end:   %time%
@echo.
