CREATE OR REPLACE FUNCTION openclinica_fdw.fdw_setup(
  IN foreign_server_host_name               TEXT,
  IN foreign_server_host_address            TEXT,
  IN foreign_server_port                    TEXT,
  IN foreign_server_database                TEXT,
  IN foreign_server_user_name               TEXT,
  IN foreign_server_user_password           TEXT,
  IN datamart_admin_role_name               TEXT DEFAULT $$dm_admin$$,
  IN foreign_server_openclinica_schema_name TEXT DEFAULT $$public$$,
  IN foreign_server_data_wrapper_kwargs     TEXT DEFAULT $$$$
) RETURNS VOID AS $b$
DECLARE
  fdw_dbname CONSTANT TEXT := $s$openclinica_fdw_db$s$;
  fdw_schema CONSTANT TEXT := $s$openclinica_fdw$s$;
  fdw_server CONSTANT TEXT := $s$openclinica_fdw_server$s$;
BEGIN
  /* revoke execution privilege from public on the dm functions */
  REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA openclinica_fdw FROM "public";

  /* Create datamart administration role with necessary privileges. */
  EXECUTE format(
    $f$CREATE ROLE %1$I INHERIT NOSUPERUSER
         NOCREATEDB NOCREATEROLE NOREPLICATION NOLOGIN;$f$,
    datamart_admin_role_name);
  EXECUTE format(
    $f$ALTER DATABASE %1$I OWNER TO %2$I;$f$,
    fdw_dbname, datamart_admin_role_name);
  EXECUTE format(
    $f$GRANT ALL ON DATABASE %1$I TO %2$I;$f$,
    fdw_dbname, datamart_admin_role_name);
  EXECUTE format(
    $f$GRANT ALL ON SCHEMA %1$I TO %2$I;$f$,
    fdw_schema, datamart_admin_role_name);
  EXECUTE format(
    $f$GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %1$I TO %2$I;$f$,
    fdw_schema, datamart_admin_role_name);

  /* add postgres to dm_admin, but for now don't impersonate */
  --GRANT datamart_admin_role_name TO postgres;

  /* Add schema for central dm queries. */
  CREATE SCHEMA dm;
  EXECUTE format(
    $f$GRANT ALL ON SCHEMA dm TO %1$I;$f$,
    datamart_admin_role_name);

  /* Add foreign server. */
  EXECUTE format(
    $f$CREATE SERVER %1$I FOREIGN DATA WRAPPER postgres_fdw
         OPTIONS (host %2$L, hostaddr %3$L, port %4$L, dbname %5$L %6$s);$f$,
    fdw_server, foreign_server_host_name, foreign_server_host_address,
    foreign_server_port, foreign_server_database,
    foreign_server_data_wrapper_kwargs);

  /* Temporarily turn off logging so FDW credentials aren't logged. */
  SET log_statement TO 'none';
  EXECUTE format(
    $f$CREATE USER MAPPING FOR %1$I SERVER %2$I
        OPTIONS (user %3$L, password %4$L);$f$,
    datamart_admin_role_name, fdw_server,
    foreign_server_user_name, foreign_server_user_password);
  SET log_statement TO 'all';

  /* So dm_admin can access and refresh foreign objects */
  EXECUTE format(
    $f$GRANT USAGE ON FOREIGN SERVER %1$I TO %2$I;$f$,
    fdw_server, datamart_admin_role_name);

  /* Import schema as dm_admin so that it owns the created objects. */
  EXECUTE format($f$SET ROLE %1$I;$f$, datamart_admin_role_name);
  EXECUTE format(
    $f$IMPORT FOREIGN SCHEMA %1$I
         FROM SERVER %2$I INTO %3$I$f$,
    foreign_server_openclinica_schema_name, fdw_server, fdw_schema);
END; $b$ LANGUAGE plpgsql VOLATILE;