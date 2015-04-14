CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata_study()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.metadata_study AS
        SELECT
            DISTINCT ON (study_name)
            study_name,
            study_status,
            study_date_created,
            study_date_updated,
            dm_clean_name_string(study_name) AS study_name_clean
        FROM
            dm.metadata;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;