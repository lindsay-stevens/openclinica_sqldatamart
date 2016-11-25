CREATE OR REPLACE FUNCTION openclinica_fdw.set_role_to_database_owner(
  IN dbname TEXT DEFAULT $s$openclinica_fdw_db$s$,
  OUT db_owner TEXT
) AS $b$
/*
Set role to the owner of the specified database, and return their name.

Useful when creating objects so  they don't need to be reassigned afterwards.
*/
BEGIN
  db_owner := (
    SELECT cast(pg_catalog.pg_get_userbyid(
                  pg_database.datdba) AS TEXT) AS owner_name
    FROM pg_catalog.pg_database
    WHERE pg_database.datname = dbname);
  EXECUTE format($f$SET ROLE %1$I;$f$, db_owner);

END;$b$ LANGUAGE plpgsql VOLATILE;