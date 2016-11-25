CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_common_matviews(
  filter_study_name TEXT DEFAULT $$$$
)
  RETURNS TEXT AS
$BODY$
DECLARE r RECORD;
BEGIN
  FOR r IN
  WITH table_list AS (
    SELECT pg_matviews.matviewname AS table_name
    FROM
      pg_catalog.pg_matviews
    WHERE
      pg_matviews.schemaname = $$dm$$
      AND pg_matviews.matviewname != $$response_sets$$
  )
  SELECT
    format(
      $f$CREATE MATERIALIZED VIEW %1$I.%2$I AS
           SELECT *
           FROM dm.%2$I
           WHERE %2$I.study_name=%3$L;
      $f$,
      study_name_clean,
      table_name,
      study_name
    ) AS create_statement,
    format(
      $f$%1$I.%2$I$f$,
      study_name_clean,
      table_name
    ) AS object_created
  FROM
    (
      SELECT *
      FROM
      (
        SELECT
          dmms.study_name_clean,
          dmms.study_name
        FROM
          dm.metadata_study AS dmms
        WHERE
          EXISTS(
            SELECT n.nspname
            FROM
              pg_namespace AS n
            WHERE
              n.nspname = dmms.study_name_clean
          )
          AND dmms.study_name ~ (
            CASE
            WHEN length(
                   filter_study_name
                 ) > 0
              THEN filter_study_name
            ELSE $$.+$$ END
          )
      ) AS sub,
      table_list
      WHERE NOT EXISTS(
        SELECT n.nspname AS schemaname
        FROM
        pg_class AS c
        LEFT JOIN
        pg_namespace AS n
          ON n.oid = c.relnamespace
        WHERE
          c.relkind = $$m$$
          AND study_name_clean = n.nspname
          AND table_name = c.relname
        ORDER BY
          c.oid
      )
    ) AS object_list
  LOOP
    EXECUTE r.create_statement;
  END LOOP;
  RETURN $$done$$;
END
$BODY$
LANGUAGE plpgsql VOLATILE;