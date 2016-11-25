CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_openclinica_matview_indexes(
  foreign_openclinica_schema_name TEXT DEFAULT $$public$$
)
  RETURNS VOID AS
$b$
/*
- get index definitions from the foreign server,
- replace the original schema name with "openclinica_fdw",
- create any such indexes that don't exist already.
*/
DECLARE
  r RECORD;
BEGIN
  FOR r IN
  SELECT
    replace(
      index_list.indexdef,
      format(
        $$ ON %1$s.$$,
        foreign_openclinica_schema_name
      ),
      $$ ON openclinica_fdw.$$
    ) AS create_statements,
    index_list.indexname
  FROM (
         SELECT DISTINCT
           fpi.indexdef,
           fpi.indexname
         FROM openclinica_fdw.ft_pg_indexes AS fpi
         WHERE
           fpi.schemaname = foreign_openclinica_schema_name
       ) AS index_list
  LOOP
    IF NOT EXISTS(
      SELECT 1
      FROM pg_catalog.pg_indexes AS pi
      WHERE
        pi.indexname = r.indexname AND
        pi.schemaname = $$openclinica_fdw$$
    )
    THEN
      EXECUTE r.create_statements;
    END IF;
  END LOOP;
END
$b$ LANGUAGE plpgsql VOLATILE;