CREATE OR REPLACE FUNCTION dm_create_dm_subjects()
    RETURNS VOID AS
    $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subjects AS
        SELECT
            DISTINCT ON (study_name, subject_id)
            cd.study_name,
            cd.site_oid,
            cd.site_name,
            cd.subject_person_id,
            cd.subject_oid,
            cd.subject_id,
            cd.study_subject_id,
            cd.subject_secondary_label,
            cd.subject_date_of_birth,
            cd.subject_sex,
            cd.subject_enrol_date,
            cd.person_id,
            cd.subject_owned_by_user,
            cd.subject_last_updated_by_user
        FROM
            dm.clinicaldata AS cd;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;