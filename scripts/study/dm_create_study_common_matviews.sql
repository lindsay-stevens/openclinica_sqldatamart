CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_common_matviews(
  filter_study_name TEXT DEFAULT $$$$)
  RETURNS TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        FOR r IN
        WITH table_list AS (
                SELECT
                    pg_matviews.matviewname AS table_name
                FROM
                    pg_catalog.pg_matviews
                WHERE
                    pg_matviews.schemaname = $$dm$$
                    AND pg_matviews.matviewname != $$response_sets$$
        )
        SELECT
            format(
                    $$ %1$s %2$s $$,
                    format(
                            $$ CREATE MATERIALIZED VIEW %1$I.%2$I AS
                       SELECT * FROM dm.%2$I WHERE %2$I.study_name=%3$L;$$,
                            study_name,
                            table_list.table_name,
                            study_name_raw
                    ),
                    (
                        CASE
                        WHEN table_list.table_name = $$clinicaldata$$
                        THEN
                            format(
                                    $$ CREATE INDEX i_%1$s_clinicaldata_item_group_oid
                           ON %1$I.clinicaldata
                           USING btree(item_group_oid);$$,
                                    study_name
                            )
                        END
                    )
            )
                AS
                create_statement,
            sub.study_name
        FROM
            (
                SELECT
                    DISTINCT ON (study_name)
                    dm_clean_name_string(
                            metadata.study_name
                    )          AS study_name,
                    study_name AS study_name_raw
                FROM
                    dm.metadata
                WHERE
                    metadata.study_name ~ (
                        CASE
                        WHEN length(
                                     filter_study_name
                             ) > 0
                        THEN filter_study_name
                        ELSE $$.+$$ END
                    )
            )
                AS
            sub,
            table_list
        LOOP
            EXECUTE r.create_statement;
        END LOOP;
        RETURN $$done$$;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;