CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subject_event_crf_status()
    RETURNS VOID AS
    $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subject_event_crf_status AS
        SELECT
            DISTINCT ON (study_name, subject_id, event_oid, event_repeat, crf_version_oid)
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
            cd.subject_last_updated_by_user,
            cd.event_oid,
            cd.event_order,
            cd.event_name,
            cd.event_repeat,
            cd.event_start,
            cd.event_end,
            cd.event_status,
            cd.event_owned_by_user,
            cd.event_last_updated_by_user,
            cd.crf_parent_oid,
            cd.crf_parent_name,
            cd.crf_version,
            cd.crf_version_oid,
            cd.crf_is_required,
            cd.crf_is_double_entry,
            cd.crf_is_hidden,
            cd.crf_null_values,
            cd.crf_date_created,
            cd.crf_last_update,
            cd.crf_date_completed,
            cd.crf_date_validate,
            cd.crf_date_validate_completed,
            cd.crf_owned_by_user,
            cd.crf_last_updated_by_user,
            cd.crf_status,
            cd.crf_validated_by_user,
            cd.crf_sdv_status,
            cd.crf_sdv_status_last_updated,
            cd.crf_sdv_by_user,
            cd.crf_interviewer_name,
            cd.crf_interview_date
        FROM
            dm.clinicaldata AS cd;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;