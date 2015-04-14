CREATE OR REPLACE FUNCTION openclinica_fdw.dm_drop_study_schema_having_new_definitions()
  RETURNS TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        FOR r IN
        SELECT
            DISTINCT
            format(
                    $query$
                    DROP TABLE IF EXISTS schema_to_drop;
                    CREATE TEMP TABLE schema_to_drop AS 
                    SELECT DISTINCT ON (dmm.study_name) dmm.study_name
                    FROM %1$I.metadata AS dmm, %1$I.timestamp_schema AS ts
                    WHERE crf_version_date_created > date_trunc($$day$$, ts.timestamp_schema)
                    OR event_date_created > date_trunc($$day$$, ts.timestamp_schema)
                    OR event_date_updated > date_trunc($$day$$, ts.timestamp_schema)
                    $query$,
                    dm_clean_name_string(
                            study_name)
            ) AS statements, 
            $query$
            SELECT dm_create_study_schemas(study_name, $$drop$$)
            FROM schema_to_drop;
            $query$ AS drop_statement
        FROM
            dm.metadata
        WHERE dm_clean_name_string(study_name) IN 
            (SELECT nspname FROM pg_catalog.pg_namespace)
        LOOP
            EXECUTE r.statements;
            EXECUTE r.drop_statement;
        END LOOP;
        RETURN $$done$$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;