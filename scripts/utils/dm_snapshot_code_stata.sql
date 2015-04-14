CREATE OR REPLACE FUNCTION public.dm_snapshot_code_stata(
  filter_study_name_schema     TEXT,
  outputdir                    TEXT,
  odbc_string_or_file_dsn_path TEXT,
  data_filter_string           TEXT DEFAULT $$$$
)
  RETURNS SETOF TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        RETURN QUERY
        WITH views AS (
                SELECT
                    *
                FROM
                    pg_catalog.pg_class AS pgc
                    INNER JOIN
                    pg_catalog.pg_namespace AS pgn
                        ON pgc.relnamespace = pgn.oid
                WHERE
                    pgn.nspname = filter_study_name_schema
        )
        SELECT
            DISTINCT ON (nspname)
            format(
                    $head$local snapshotdir="%1$s"$head$,
                    outputdir
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            DISTINCT ON (nspname)
            format(
                    $head$local data_filter_string="%1$s"$head$,
                    data_filter_string
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            DISTINCT ON (nspname)
            format(
                    $head$local odbc_string_or_file_dsn_path="%1$s"$head$,
                    odbc_string_or_file_dsn_path
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            format(
                    $line$odbc load, exec("SELECT * FROM %1$s.%2$s `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
                    save "`snapshotdir'/%3$s.dta"
                    clear$line$,
                    filter_study_name_schema,
                    relname,
                    substring(
                            relname
                            FROM
                            4)
            )
        FROM
            views
        WHERE
            views.relkind = $$v$$
        UNION ALL
        SELECT
            format(
                    $line$odbc load, exec("SELECT * FROM %1$s.%2$s") connectionstring("`odbc_string_or_file_dsn_path'")
                    save "`snapshotdir'/%2$s.dta"
                    clear$line$,
                    filter_study_name_schema,
                    relname
            )
        FROM
            views
        WHERE
            views.relkind = $$m$$
            AND views.relname NOT LIKE $$ig_%$$
            AND views.relname != $$clinicaldata$$;
        RETURN;
    END;
    $BODY$
LANGUAGE plpgsql STABLE;