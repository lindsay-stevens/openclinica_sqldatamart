CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_openclinica(
  foreign_openclinica_schema_name TEXT DEFAULT $$public$$
)
  RETURNS VOID AS
  $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN
        WITH table_list AS (
                SELECT
                    ft_pg_class.relname AS table_name,
                    array_to_string(
                            array_agg(
                                    concat_ws(
                                            $$ $$,
                                            ft_pg_attribute.attname :: TEXT,
                                            format_type(
                                                    ft_pg_attribute.atttypid,
                                                    ft_pg_attribute.atttypmod
                                            )
                                    )
                                    ORDER
                                    BY
                                    ft_pg_attribute.attnum
                            ),
                            $$, $$
                    )                   AS table_def
                FROM
                    ft_pg_attribute
                    LEFT JOIN
                    ft_pg_class
                        ON ft_pg_class.oid = ft_pg_attribute.attrelid
                    LEFT JOIN
                    ft_pg_namespace
                        ON ft_pg_class.relnamespace = ft_pg_namespace.oid
                WHERE
                    ft_pg_namespace.nspname = foreign_openclinica_schema_name
                    AND NOT ft_pg_attribute.attisdropped
                    AND ft_pg_attribute.attnum > 0
                    AND ft_pg_class.relkind IN ($$v$$, $$r$$)
                GROUP BY
                    ft_pg_namespace.nspname,
                    ft_pg_class.relname
        )
        SELECT
            format(
                    $$ CREATE FOREIGN TABLE openclinica_fdw.ft_%1$s (%2$s)
                       SERVER openclinica_fdw_server OPTIONS (schema_name %3$L,
                       table_name %1$L, updatable 'false'); $$,
                    table_list.table_name,
                    table_list.table_def,
                    foreign_openclinica_schema_name
            ) AS create_statements
        FROM
            table_list
        LOOP
            EXECUTE r.create_statements;
        END LOOP;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;