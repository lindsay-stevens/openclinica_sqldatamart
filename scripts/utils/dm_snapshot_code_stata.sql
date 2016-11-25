CREATE OR REPLACE FUNCTION public.dm_snapshot_code_stata(
  IN  study_schema    TEXT,
  IN  output_path     TEXT,
  IN  odbc_connection TEXT,
  IN  data_filter     TEXT DEFAULT $$$$,
  OUT cmd_text_out    TEXT
) RETURNS SETOF TEXT AS $b$
BEGIN
  RETURN QUERY
  WITH script_header AS (
    SELECT
      s.study_schema AS nspname,
      t.suborder,
      t.cmd_text
    FROM
    (
      VALUES
        (1, format($f$local snapshotdir="%1$s"$f$, output_path)),
        (2, format($f$local odbc_dsn="%1$s"$f$, odbc_connection)),
        (3, format($f$local data_filter="%1$s"$f$, data_filter))
    ) AS t(suborder, cmd_text), (SELECT study_schema) AS s
)
  SELECT cmd_text AS cmd_text_out
  FROM
    (
      SELECT
        nspname,
        '' AS relname,
        1 AS ordering,
        suborder,
        cmd_text
      FROM script_header
      UNION ALL
      SELECT
        nspname,
        relname,
        ordering,
        suborder,
        cmd_text
      FROM dm.snapshot_code_stata_cmds
      WHERE nspname = study_schema
    ) AS u
  ORDER BY
  nspname,
  relname NULLS FIRST,
  ordering,
  suborder,
  cmd_text;
END $b$ LANGUAGE plpgsql STABLE;