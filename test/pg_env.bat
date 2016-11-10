:: Change this to the install path in your environment, if it is different.
:: The above should contain directories "bin", "lib", "share", and so on.
:: pg_data and PGDATA both set to make sure we don't delete another cluster.
@ECHO OFF
@SET "pg_install_path=C:\Program Files\PostgreSQL\9.6"
@SET "PATH=%pg_install_path%\bin;%PATH%"
@SET pg_data=%~dp0postgres_data
@SET PGDATA=%pg_data%
@SET PGHOST=localhost
@SET PGHOSTADDR=127.0.0.1
@SET PGDATABASE=postgres
@SET PGUSER=postgres
@SET PGPASSWORD=password
@SET PGPORT=5446
@SET PGLOCALEDIR=%pg_install_path%\share\locale
@SET PGCLIENTENCODING=UTF8
@ECHO ON
