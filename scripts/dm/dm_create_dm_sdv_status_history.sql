CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_sdv_status_history()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.sdv_status_history AS
        SELECT
            secs.study_name,
            secs.subject_id,
            secs.event_name,
            secs.event_repeat,
            secs.event_status,
            secs.crf_parent_name,
            secs.crf_status,
            pale.new_value  AS audit_sdv_status,
            pua.user_name   AS audit_sdv_user,
            pale.audit_date AS audit_sdv_timestamp,
            CASE
            WHEN pale.audit_date IS NULL
            THEN NULL
            ELSE CASE
                 WHEN secs.crf_sdv_status_last_updated = pale.audit_date
                 THEN 'current'
                 WHEN secs.crf_sdv_status_last_updated <> pale.audit_date
                 THEN 'history'
                 END
            END             AS audit_sdv_current_or_history
        FROM
            (
                SELECT
                    DISTINCT ON (study_name, subject_id, event_oid, crf_version_oid)
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
                    cd.event_crf_id,
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
                    dm.clinicaldata AS cd
            ) AS secs
            LEFT JOIN
            (
                SELECT
                    *
                FROM
                    openclinica_fdw.audit_log_event
                WHERE
                    audit_log_event_type_id = 32
            ) AS pale
                ON pale.event_crf_id = secs.event_crf_id
            LEFT JOIN
            openclinica_fdw.user_account AS pua
                ON pale.user_id = pua.user_id
        ORDER BY
            secs.study_name,
            secs.subject_id,
            secs.event_name,
            secs.event_repeat,
            secs.crf_parent_name,
            pale.audit_date DESC
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;