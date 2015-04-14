CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subject_event_crf_expected()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subject_event_crf_expected AS
        SELECT
            s.study_name,
            s.site_oid,
            s.subject_id,
            e.event_oid,
            e.crf_parent_name
        FROM
            (
                SELECT
                    DISTINCT
                    clinicaldata.study_name,
                    clinicaldata.site_oid,
                    clinicaldata.site_name,
                    clinicaldata.subject_id
                FROM
                    dm.clinicaldata
            ) AS s,
            (
                SELECT
                    DISTINCT
                    metadata.study_name,
                    metadata.event_oid,
                    metadata.crf_parent_name
                FROM
                    dm.metadata
            ) AS e
        WHERE
            s.study_name = e.study_name
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;