:: Setup the environment for creating a throw-away database cluster for this demo.
call %~dp0postgres\pg_env.bat

echo.
echo Removing previous data directory if it exists, at: %~dp0postgres\data
echo.
rmdir %~dp0postgres\data /s /q

:: Initdb doesn't use PGPASSWORD, but we can write it to a file and provide that.
echo.
echo Initialising data directory at: %~dp0postgres\data
echo.
echo %PGPASSWORD%>postgres\.pgpass
initdb -D %~dp0postgres\data -U postgres -A md5 -E UTF-8 --pwfile=%~dp0postgres\.pgpass

echo.
echo Finished step 1. This window can be closed.
echo.

pause