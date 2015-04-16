CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_schemas(
  filter_study_name TEXT DEFAULT $$$$
)
  RETURNS TEXT AS
  $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN
        SELECT
            format(
                    $$CREATE SCHEMA %1$I; 
                    CREATE MATERIALIZED VIEW %1$I.timestamp_schema AS 
                    SELECT %1$L::text AS study_name, now() AS timestamp_schema;
                    CREATE MATERIALIZED VIEW %1$I.timestamp_data AS 
                    SELECT %1$L::text AS study_name, now() as timestamp_data;$$,
                    sub.study_name_clean
            ) AS create_statement,
            sub.study_name_clean
        FROM
            (
                SELECT
                    dmms.study_name_clean
                FROM
                    dm.metadata_study AS dmms
                WHERE
                    dmms.study_status != $$removed$$
                    AND NOT EXISTS(
                        SELECT
                            n.nspname
                        FROM
                            pg_namespace AS n
                        WHERE
                            n.nspname = dmms.study_name_clean
                    )
                    AND dmms.study_name ~ (
                        CASE
                        WHEN length(
                                     filter_study_name
                             ) > 0
                        THEN filter_study_name
                        ELSE $$.+$$ END
                    )
            ) AS sub
        LOOP
            EXECUTE r.create_statement;
        END LOOP;
        RETURN $$done$$;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;