@ECHO OFF
REM The script sets environment variables helpful for PostgreSQL
call %~dp0..\demo0_set_pg_install_path.bat

@SET "PATH=%pg_install_path%\bin;%PATH%"
@SET PGDATA=%~dp0data
@SET PGHOST=localhost
@SET PGHOSTADDR=127.0.0.1
@SET PGDATABASE=postgres
@SET PGUSER=postgres
@SET PGPASSWORD=password
@SET PGPORT=5446
@SET PGLOCALEDIR=%pg_install_path%\share\locale
@SET PGCLIENTENCODING=UTF8
