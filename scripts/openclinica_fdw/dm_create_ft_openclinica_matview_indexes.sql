CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_openclinica_matview_indexes(
  foreign_openclinica_schema_name TEXT DEFAULT $$public$$
)
  RETURNS VOID AS
  $BODY$
    DECLARE
        r RECORD;
        foreign_openclinica_schema_name ALIAS FOR foreign_openclinica_schema_name;
    BEGIN
        FOR r IN
        WITH table_list AS (
            SELECT
                DISTINCT
                ft_pg_indexes.indexdef,
                ft_pg_indexes.indexname
            FROM
                ft_pg_indexes
            WHERE
                ft_pg_indexes.schemaname = foreign_openclinica_schema_name
        )
        SELECT
            replace(
                table_list.indexdef,
                format(
                        $$ ON %1$s.$$,
                        foreign_openclinica_schema_name
                ),
                $$ ON openclinica_fdw.$$
            ) AS create_statements,
            indexname
        FROM
            table_list
        LOOP
            IF NOT EXISTS(
                SELECT
                    1
                FROM
                    pg_indexes
                WHERE
                    pg_indexes.indexname = r.indexname AND
                    pg_indexes.schemaname = $$openclinica_fdw$$
            ) THEN
                EXECUTE r.create_statements;
            END IF;
        END LOOP;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;