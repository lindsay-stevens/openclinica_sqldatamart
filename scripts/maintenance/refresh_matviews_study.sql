CREATE VIEW dm.maint_refresh_matviews_study AS
  /* Refresh if study is available, or if the study is locked or frozen then
     refresh until end of day after last update */
  SELECT
    dm_refresh_matview(mv.schemaname, mv.matviewname)
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
        INNER JOIN
        (
          SELECT
            ddmd.study_name
          FROM (
                 SELECT
                   DISTINCT ON (dmd.study_name)
                   dmd.study_name,
                   dmd.study_status,
                   dmd.study_date_updated
                 FROM
                   dm.metadata AS dmd
               ) AS ddmd
          WHERE
            ddmd.study_status = $$available$$
            OR (
              ddmd.study_status IN ($$locked$$, $$frozen$$)
              AND ddmd.study_date_updated >= (
                date_trunc($$day$$, now()) - INTERVAL '1 day')
            )
        ) AS study_names
          ON openclinica_fdw.dm_clean_name_string(study_names.study_name) = n.nspname
      WHERE
        c.relkind = $$m$$
        AND c.relname != $$timestamp_schema$$
      ORDER BY
        c.oid
    ) AS mv;