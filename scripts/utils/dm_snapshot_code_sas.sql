CREATE OR REPLACE FUNCTION public.dm_snapshot_code_sas(
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
                    $head$%%LET snapshotdir=%1$s; LIBNAME snapshot "&snapshotdir"; RUN;$head$,
                    outputdir
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            DISTINCT ON (nspname)
            format(
                    $head$%%LET data_filter_string=%1$s;$head$,
                    data_filter_string
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            DISTINCT ON (nspname)
            format(
                    $head$PROC SQL; CONNECT TO odbc AS pgodbc (NOPROMPT="%1$s");$head$,
                    odbc_string_or_file_dsn_path
            ) AS statements
        FROM
            views
        UNION ALL
        SELECT
            format(
                    $line$create table snapshot.%2$s as select * from connection to pgodbc
                    (select * from %1$s.%3$s &data_filter_string );$line$,
                    filter_study_name_schema,
                    substring(relname from 4 for 32),
                    relname
            )
        FROM
            views
        WHERE
            views.relkind = $$v$$
        UNION ALL
        SELECT
            format(
                    $line$create table snapshot.%2$s as select * from connection to pgodbc
                    (select * from %1$s.%2$s);$line$,
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
