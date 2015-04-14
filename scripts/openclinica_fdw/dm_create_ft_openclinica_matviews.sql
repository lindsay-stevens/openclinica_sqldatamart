CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_openclinica_matviews()
  RETURNS VOID AS
  $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN
        WITH table_list AS (
            SELECT
                pg_class.relname AS table_name
            FROM
                pg_class
                LEFT JOIN
                pg_namespace
                    ON pg_class.relnamespace = pg_namespace.oid
            WHERE
                pg_namespace.nspname = $$openclinica_fdw$$
                AND pg_class.relkind = $$f$$
                AND pg_class.relname NOT LIKE $$ft_pg_%$$
        )
        SELECT
            format(
                    $$ CREATE MATERIALIZED VIEW openclinica_fdw.%2$I AS
                       SELECT * FROM openclinica_fdw.%1$I; $$,
                    table_list.table_name,
                    substring(
                            table_list.table_name,
                            4
                    )
            ) AS create_statements
        FROM
            table_list
        LOOP
            EXECUTE r.create_statements;
        END LOOP;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;