CREATE OR REPLACE FUNCTION openclinica_fdw.dm_reassign_owner_study_matviews(
  to_role TEXT DEFAULT $$dm_admin$$
)
  RETURNS TEXT AS
$BODY$
DECLARE r RECORD;
BEGIN
  FOR r IN
  SELECT format(
           $$ ALTER MATERIALIZED VIEW %1$I.%2$I OWNER TO %3$I;$$,
           pgm.schemaname,
           pgm.matviewname,
           to_role
         ) AS statements
  FROM
    pg_catalog.pg_matviews AS pgm
  WHERE
    pgm.schemaname IN (
      SELECT study_name_clean
      FROM dm.metadata_study)
    AND pgm.matviewowner != to_role
  LOOP
    EXECUTE r.statements;
  END LOOP;
  RETURN $$done$$;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;