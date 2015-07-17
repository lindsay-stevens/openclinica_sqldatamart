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
            concat(
                $line$odbc load, exec("SELECT * $line$,
                format(
                    $line$FROM %1$s.%2$s `data_filter_string'") $line$,
                    filter_study_name_schema,
                    relname
                ),
                $line$connectionstring("`odbc_string_or_file_dsn_path'") $line$,
                chr(10),
                format(
                    $line$save "`snapshotdir'/%1$s.dta"$line$,
                    substring(relname FROM 4)
                ),
                chr(10),
                $line$clear$line$
            )
        FROM
            views
        WHERE
            views.relkind = $$v$$
        UNION ALL
        SELECT
            concat(
                $line$odbc load, exec("SELECT * $line$,
                format(
                    $line$FROM %1$s.%2$s `data_filter_string'") $line$,
                    filter_study_name_schema,
                    relname
                ),
                $line$connectionstring("`odbc_string_or_file_dsn_path'") $line$,
                chr(10),
                format(
                    $line$save "`snapshotdir'/%1$s.dta"$line$,
                    relname
                ),
                chr(10),
                $line$clear$line$
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