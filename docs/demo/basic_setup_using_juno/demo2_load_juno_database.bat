call %~dp0postgres\pg_env.bat
call %~dp0util_restart.bat

psql -d postgres -c "DROP DATABASE IF EXISTS openclinica;"
psql -d postgres -c "CREATE DATABASE openclinica;"
psql -d openclinica -f %~dp0juno.backup

echo.
echo Finished step 2. This window can be closed.
echo To keep the database running, leave this window open.
echo.