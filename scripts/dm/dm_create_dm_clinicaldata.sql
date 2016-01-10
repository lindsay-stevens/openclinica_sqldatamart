CREATE OR REPLACE FUNCTION dm_create_dm_clinicaldata()
    RETURNS VOID AS
    $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.clinicaldata AS
        WITH ec_ale_sdv AS (
                SELECT
                    ale.event_crf_id,
                    max(
                            ale.audit_date) AS audit_date
                FROM
                    openclinica_fdw.audit_log_event AS ale
                WHERE
                    ale.event_crf_id IS NOT NULL
                    AND ale.audit_log_event_type_id = 32 -- event crf sdv status
                GROUP BY
                    ale.event_crf_id
        )
        SELECT
            COALESCE(
                    parents.name,
                    study.name,
                    'no parent study')    AS study_name,
            study.oc_oid                  AS site_oid,
            study.name                    AS site_name,
            sub.unique_identifier         AS subject_person_id,
            ss.oc_oid                     AS subject_oid,
            ss.label                      AS subject_id,
            ss.study_subject_id,
            ss.secondary_label            AS subject_secondary_label,
            sub.date_of_birth             AS subject_date_of_birth,
            sub.gender                    AS subject_sex,
            sub.subject_id                AS subject_id_seq,
            ss.enrollment_date            AS subject_enrol_date,
            sub.unique_identifier         AS person_id,
            ss.owner_id                   AS ss_owner_id,
            ss.update_id                  AS ss_update_id,
            sed.oc_oid                    AS event_oid,
            sed.ordinal                   AS event_order,
            sed.name                      AS event_name,
            se.study_event_id,
            se.sample_ordinal             AS event_repeat,
            se.date_start                 AS event_start,
            se.date_end                   AS event_end,
            ses.name                      AS event_status,
            se.owner_id                   AS se_owner_id,
            se.update_id                  AS se_update_id,
            crf.oc_oid                    AS crf_parent_oid,
            crf.name                      AS crf_parent_name,
            cv.name                       AS crf_version,
            cv.oc_oid                     AS crf_version_oid,
            edc.required_crf              AS crf_is_required,
            edc.double_entry              AS crf_is_double_entry,
            edc.hide_crf                  AS crf_is_hidden,
            edc.null_values               AS crf_null_values,
            edc.status_id                 AS edc_status_id,
            ec.event_crf_id,
            ec.date_created               AS crf_date_created,
            ec.date_updated               AS crf_last_update,
            ec.date_completed             AS crf_date_completed,
            ec.date_validate              AS crf_date_validate,
            ec.date_validate_completed    AS crf_date_validate_completed,
            ec.owner_id                   AS ec_owner_id,
            ec.update_id                  AS ec_update_id,
            CASE
            WHEN ses.subject_event_status_id IN
                 (5, 6, 7) --stopped,skipped,locked
            THEN 'locked'
            WHEN cv.status_id <> 1 --available
            THEN 'locked'
            WHEN ec.status_id = 1 --available
            THEN 'initial data entry'
            WHEN ec.status_id = 2 --unavailable
            THEN
                CASE
                WHEN edc.double_entry = TRUE
                THEN 'validation completed'
                WHEN edc.double_entry = FALSE
                THEN 'data entry complete'
                ELSE 'unhandled'
                END
            WHEN ec.status_id = 4 --pending
            THEN
                CASE
                WHEN ec.validator_id <>
                     0 --default zero, blank if event_crf created by insertaction
                THEN 'double data entry'
                WHEN ec.validator_id = 0
                THEN 'initial data entry complete'
                ELSE 'unhandled'
                END
            ELSE ec_s.name
            END                           AS crf_status,
            ec.validator_id,
            ec.sdv_status                 AS crf_sdv_status,
            ec_ale_sdv.audit_date         AS crf_sdv_status_last_updated,
            ec.sdv_update_id,
            ec.interviewer_name           AS crf_interviewer_name,
            ec.date_interviewed           AS crf_interview_date,
            sct.label                     AS crf_section_label,
            sct.title                     AS crf_section_title,
            ig.oc_oid                     AS item_group_oid,
            ig.name                       AS item_group_name,
            id.ordinal                    AS item_group_repeat,
            ifm.ordinal                   AS item_form_order,
            ifm.question_number_label     AS item_question_number,
            i.oc_oid                      AS item_oid,
            i.units                       AS item_units,
            id.code                      AS item_data_type,
            rt.name            AS item_response_type,
            CASE
            WHEN response_sets.label IN ('text', 'textarea')
            THEN NULL
            ELSE response_sets.label
            END                           AS item_response_set_label,
            response_sets.response_set_id AS item_response_set_id,
            response_sets.version_id      AS item_response_set_version,
            i.name                        AS item_name,
            i.description                 AS item_description,
            id.value                      AS item_value,
            id.date_created               AS item_value_created,
            id.date_updated               AS item_value_last_updated,
            id.owner_id                   AS id_owner_id,
            id.update_id                  AS id_update_id,
            id.item_data_id,
            response_sets.option_text,
            ua_ss_o.user_name             AS subject_owned_by_user,
            ua_ss_u.user_name             AS subject_last_updated_by_user,
            ua_se_o.user_name             AS event_owned_by_user,
            ua_se_u.user_name             AS event_last_updated_by_user,
            ua_ec_o.user_name             AS crf_owned_by_user,
            ua_ec_u.user_name             AS crf_last_updated_by_user,
            ua_ec_v.user_name             AS crf_validated_by_user,
            (CASE
             WHEN ec.sdv_status IS FALSE
             THEN NULL
             WHEN ec.sdv_status IS TRUE
             THEN ua_ec_s.user_name
             ELSE 'unhandled'
             END)                         AS crf_sdv_by_user,
            ua_id_o.user_name             AS item_value_owned_by_user,
            ua_id_u.user_name             AS item_value_last_updated_by_user
        FROM
            openclinica_fdw.study
            LEFT JOIN
            (
                SELECT
                    study.*
                FROM
                    openclinica_fdw.study
                WHERE
                    study.status_id NOT IN
                    (5, 7) /*removed, auto-removed*/) AS parents
                ON parents.study_id = study.parent_study_id
            INNER JOIN
            openclinica_fdw.study_subject AS ss
                ON ss.study_id = study.study_id
            INNER JOIN
            openclinica_fdw.subject AS sub
                ON sub.subject_id = ss.subject_id
            INNER JOIN
            openclinica_fdw.study_event AS se
                ON se.study_subject_id = ss.study_subject_id
            INNER JOIN
            openclinica_fdw.study_event_definition AS sed
                ON sed.study_event_definition_id = se.study_event_definition_id
            INNER JOIN
            openclinica_fdw.subject_event_status AS ses
                ON ses.subject_event_status_id = se.subject_event_status_id
            INNER JOIN
            openclinica_fdw.event_definition_crf AS edc
                ON edc.study_event_definition_id = se.study_event_definition_id
            INNER JOIN
            openclinica_fdw.event_crf AS ec
                ON se.study_event_id = ec.study_event_id
                   AND ec.study_subject_id = ss.study_subject_id
            INNER JOIN
            openclinica_fdw.status AS ec_s
                ON ec.status_id = ec_s.status_id
            LEFT JOIN
            ec_ale_sdv
                ON ec_ale_sdv.event_crf_id = ec.event_crf_id
            INNER JOIN
            openclinica_fdw.crf_version AS cv
                ON cv.crf_version_id = ec.crf_version_id
                   AND cv.crf_id = edc.crf_id
            INNER JOIN
            openclinica_fdw.crf
                ON crf.crf_id = cv.crf_id
                   AND crf.crf_id = edc.crf_id
            INNER JOIN
            openclinica_fdw.item_group AS ig
                ON ig.crf_id = crf.crf_id
            INNER JOIN
            openclinica_fdw.item_group_metadata AS igm
                ON igm.item_group_id = ig.item_group_id
                   AND igm.crf_version_id = cv.crf_version_id
            INNER JOIN
            openclinica_fdw.item_form_metadata AS ifm
                ON cv.crf_version_id = ifm.crf_version_id
            INNER JOIN
            openclinica_fdw.item AS i
                ON i.item_id = ifm.item_id
                   AND i.item_id = igm.item_id
            INNER JOIN
            openclinica_fdw.item_data_type AS id
                ON id.item_data_type_id = i.item_data_type_id
            INNER JOIN
            openclinica_fdw.response_set AS rs
                ON rs.response_set_id = ifm.response_set_id
                   AND rs.version_id = ifm.crf_version_id
            INNER JOIN
            openclinica_fdw.response_type AS rt
                ON rs.response_type_id = rt.response_type_id
            INNER JOIN
            openclinica_fdw."section" AS sct
                ON sct.crf_version_id = cv.crf_version_id
                   AND sct.section_id = ifm.section_id
            INNER JOIN
            openclinica_fdw.item_data AS id
                ON id.item_id = i.item_id
                   AND id.event_crf_id = ec.event_crf_id
            LEFT JOIN
            dm.response_sets
                ON response_sets.response_set_id = rs.response_set_id
                   AND response_sets.version_id = rs.version_id
                   AND response_sets.option_value = id.value
                   AND id.value != $$$$
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ss_o
                ON ua_ss_o.user_id = ss.owner_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ss_u
                ON ua_ss_u.user_id = ss.update_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_se_o
                ON ua_se_o.user_id = se.owner_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_se_u
                ON ua_se_u.user_id = se.update_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ec_o
                ON ua_ec_o.user_id = ec.owner_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ec_u
                ON ua_ec_u.user_id = ec.update_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ec_v
                ON ua_ec_v.user_id = ec.validator_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_ec_s
                ON ua_ec_s.user_id = ec.sdv_update_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_id_o
                ON ua_id_o.user_id = id.owner_id
            LEFT JOIN
            openclinica_fdw.user_account AS ua_id_u
                ON ua_id_u.user_id = id.update_id
        WHERE
            study.status_id NOT IN (5, 7) --removed, auto-removed
            AND ss.status_id NOT IN (5, 7)
            AND se.status_id NOT IN (5, 7)
            AND ec.status_id NOT IN (5, 7)
            AND sed.status_id NOT IN (5, 7)
            AND edc.status_id NOT IN (5, 7)
            AND cv.status_id NOT IN (5, 7)
            AND crf.status_id NOT IN (5, 7)
            AND ig.status_id NOT IN (5, 7)
            AND i.status_id NOT IN (5, 7)
            AND sct.status_id NOT IN (5, 7)
            AND id.status_id NOT IN (5, 7)
            -- the follow conditions result in study level event definitions
            AND
            CASE WHEN
                CASE WHEN edc.parent_id IS NOT NULL THEN
                    edc.event_definition_crf_id =
                    (
                        SELECT
                            max(
                                    edc_max.event_definition_crf_id) edc_max
                        FROM
                            openclinica_fdw.event_definition_crf AS edc_max
                        WHERE
                            edc_max.study_event_definition_id
                            =
                            se.study_event_definition_id
                            AND
                            edc_max.crf_id = crf.crf_id
                        GROUP BY
                            edc_max.study_event_definition_id,
                            edc_max.crf_id) END
            THEN TRUE
            ELSE
                CASE WHEN edc.parent_id IS NULL AND
                          (
                              SELECT
                                  count(
                                          edc_count.event_definition_crf_id) edc_count
                              FROM
                                  openclinica_fdw.event_definition_crf AS edc_count
                              WHERE
                                  edc_count.study_event_definition_id =
                                  se.study_event_definition_id
                                  AND edc_count.crf_id = crf.crf_id
                              GROUP BY
                                  edc_count.study_event_definition_id,
                                  edc_count.crf_id) = 1
                THEN
                    edc.event_definition_crf_id =
                    (
                        SELECT
                            min(
                                    edc_min.event_definition_crf_id) edc_min
                        FROM
                            openclinica_fdw.event_definition_crf AS edc_min
                        WHERE
                            edc_min.study_event_definition_id =
                            se.study_event_definition_id
                            AND edc_min.crf_id = crf.crf_id
                        GROUP BY
                            edc_min.study_event_definition_id,
                            edc_min.crf_id)
                END
            END;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;
