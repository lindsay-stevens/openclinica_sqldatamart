:: Change this to the install path in your environment, if it is different.
:: The above should contain directories "bin", "lib", "share", and so on.
:: pg_data and PGDATA both set to make sure we don't delete another cluster.
@echo off
@set "pg_install_path=C:\Program Files\PostgreSQL\9.6"
@set "PATH=%pg_install_path%\bin;%PATH%"
@set pg_data=%~dp0postgres_data
@set PGDATA=%pg_data%
@set PGHOST=localhost
@set PGDATABASE=postgres
@set PGUSER=postgres
@set PGPASSWORD=password
@set PGPORT=5446
@set PGLOCALEDIR=%pg_install_path%\share\locale
@set PGCLIENTENCODING=UTF8
@echo on
