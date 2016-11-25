CREATE VIEW dm.maint_refresh_matviews_dm AS
  SELECT
    dm_refresh_matview(
      mv.schemaname,
      mv.matviewname)
  FROM
    (
      SELECT
        n.nspname AS schemaname,
        c.relname AS matviewname
      FROM
        pg_class c
        LEFT JOIN
        pg_namespace n
          ON n.oid = c.relnamespace
      WHERE
        c.relkind = $$m$$ AND n.nspname = $$dm$$
      ORDER BY
        c.oid
    ) AS mv;