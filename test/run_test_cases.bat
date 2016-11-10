call %~dp0pg_env.bat
psql -d openclinica_fdw_db -c "\x" -f test_cases\test_dm_clean_name_string.sql

pause