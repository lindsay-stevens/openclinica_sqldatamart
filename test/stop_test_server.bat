:: Set environment variables for the testing server.
call %~dp0pg_env.bat
@echo off

@echo Stopping test server...
pg_ctl stop
