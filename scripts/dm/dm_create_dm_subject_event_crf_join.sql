CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subject_event_crf_join()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subject_event_crf_join AS
        SELECT
            e.study_name,
            e.site_oid,
            s.site_name,
            s.subject_person_id,
            s.subject_oid,
            e.subject_id,
            s.study_subject_id,
            s.subject_secondary_label,
            s.subject_date_of_birth,
            s.subject_sex,
            s.subject_enrol_date,
            s.person_id,
            s.subject_owned_by_user,
            s.subject_last_updated_by_user,
            e.event_oid,
            s.event_order,
            s.event_name,
            s.event_repeat,
            s.event_start,
            s.event_end,
            CASE WHEN s.event_status IS NOT NULL
            THEN s.event_status
            ELSE $$not scheduled$$
            END AS event_status,
            s.event_owned_by_user,
            s.event_last_updated_by_user,
            s.crf_parent_oid,
            e.crf_parent_name,
            s.crf_version,
            s.crf_version_oid,
            s.crf_is_required,
            s.crf_is_double_entry,
            s.crf_is_hidden,
            s.crf_null_values,
            s.crf_date_created,
            s.crf_last_update,
            s.crf_date_completed,
            s.crf_date_validate,
            s.crf_date_validate_completed,
            s.crf_owned_by_user,
            s.crf_last_updated_by_user,
            s.crf_status,
            s.crf_validated_by_user,
            s.crf_sdv_status,
            s.crf_sdv_status_last_updated,
            s.crf_sdv_by_user,
            s.crf_interviewer_name,
            s.crf_interview_date
        FROM
            dm.subject_event_crf_expected AS e
            LEFT JOIN
            dm.subject_event_crf_status AS s
                ON
                    s.subject_id = e.subject_id
                    AND
                    s.event_oid = e.event_oid
                    AND
                    s.crf_parent_name = e.crf_parent_name
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;