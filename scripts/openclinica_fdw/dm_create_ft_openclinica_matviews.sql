CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_openclinica_matviews()
  RETURNS VOID AS
$b$
/*
- get a list of the foreign tables in the openclinica_fdw schema,
- exclude the "ft_pg_" tables which are for retrieving postgres metadata,
- create materialized views for all such tables.
*/
DECLARE
  r RECORD;
BEGIN
  FOR r IN
  SELECT format(
           $$ CREATE VIEW openclinica_fdw.%2$I AS
              SELECT * FROM openclinica_fdw.%1$I; $$,
           table_list.table_name,
           substring(table_list.table_name, 4)
         ) AS create_statements
  FROM (
         SELECT pc.relname AS table_name
         FROM pg_catalog.pg_class AS pc
         LEFT JOIN pg_catalog.pg_namespace AS pn
           ON pc.relnamespace = pn.oid
         WHERE
           pn.nspname = $$openclinica_fdw$$
           AND pc.relkind = $$f$$
           AND pc.relname NOT LIKE $$ft_pg_%$$
       ) AS table_list
  LOOP
    EXECUTE r.create_statements;
  END LOOP;
END
$b$ LANGUAGE plpgsql VOLATILE;