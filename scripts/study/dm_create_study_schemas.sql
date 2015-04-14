CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_schemas(
  filter_study_name TEXT DEFAULT $$$$,
  create_or_drop    TEXT DEFAULT $$create$$
)
  RETURNS TEXT AS
  $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN
        SELECT
            format(
                    $$CREATE SCHEMA %1$I AUTHORIZATION dm_admin; 
                    CREATE MATERIALIZED VIEW %1$I.timestamp_schema AS 
                    SELECT %1$L::text AS study_name, now() AS timestamp_schema;
                    CREATE MATERIALIZED VIEW %1$I.timestamp_data AS 
                    SELECT %1$L::text AS study_name, now() as timestamp_data;$$,
                    sub.study_name
            ) AS create_statement,
            format(
                    $$DROP SCHEMA %1$I CASCADE;$$,
                    sub.study_name
            ) AS drop_statement,
            sub.study_name
        FROM
            (
                SELECT
                    DISTINCT ON (metadata.study_name)
                    dm_clean_name_string(
                            metadata.study_name
                    ) AS study_name
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
            ) AS sub
        LOOP
            IF create_or_drop = $$create$$ THEN
                EXECUTE r.create_statement;
            ELSIF create_or_drop = $$drop$$ THEN
                EXECUTE r.drop_statement;
            END IF;
        END LOOP;
        RETURN $$done$$;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;