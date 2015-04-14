CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subject_event_crf_status()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subject_event_crf_status AS
    WITH status_filter AS (
            SELECT
                status.status_id,
                status.name
            FROM
                openclinica_fdw.status
            WHERE
                status.name
                NOT IN ($$removed$$, $$auto-removed$$)
    ), user_id_name AS (
    SELECT user_account.user_id, user_account.user_name
        FROM openclinica_fdw.user_account
    ), study_details AS (
    SELECT
        COALESCE(
                parent_study.oc_oid,
                study.oc_oid,
                $$no parent study$$) AS study_oid,
        COALESCE(
                parent_study.name,
                study.name,
                $$no parent study$$) AS study_name,
        COALESCE(
                parent_study.study_id,
                study.study_id) AS   study_id,
        study.oc_oid                 AS site_oid,
        study.name                   AS site_name,
        study.study_id as site_id
    FROM
        openclinica_fdw.study
        LEFT JOIN
        (
            SELECT
                study.study_id,
                study.oc_oid,
                study.name
            FROM
                openclinica_fdw.study
                INNER JOIN
                status_filter AS status_pstudy
                    ON status_pstudy.status_id = study.status_id
        ) AS parent_study
            ON parent_study.study_id = study.parent_study_id
        INNER JOIN
        status_filter AS status_study
            ON status_study.status_id = study.status_id      
    ), subject_details AS (
            SELECT
                ss.study_subject_id   AS study_subject_id_seq,
                ss.label              AS subject_id,
                ss.secondary_label    AS subject_secondary_label,
                ss.subject_id         AS subject_id_seq,
                ss.study_id           AS subject_study_id,
                ss.enrollment_date    AS subject_enrol_date,
                ss.date_created       AS subject_date_created,
                ss.date_updated       AS subject_date_updated,
                ua_ss_o.user_name     AS subject_created_by,
                ua_ss_u.user_name     AS subject_updated_by,
                ss.oc_oid             AS subject_oid,
                sub.date_of_birth     AS subject_date_of_birth,
                sub.gender            AS subject_sex,
                sub.unique_identifier AS subject_person_id,
                status_ss.name        AS subject_status
            FROM
                openclinica_fdw.study_subject AS ss
                INNER JOIN
                openclinica_fdw.subject AS sub
                    ON ss.subject_id = sub.subject_id
                INNER JOIN
                status_filter AS status_ss
                    ON ss.status_id = status_ss.status_id
                INNER JOIN
                user_id_name AS ua_ss_o
                    ON ss.owner_id = ua_ss_o.user_id
                LEFT JOIN
                user_id_name AS ua_ss_u
                    ON ss.owner_id = ua_ss_u.user_id
    ), event_details AS (
            SELECT
                se.study_event_id             AS study_event_id_seq,
                se.study_subject_id           AS event_study_subject_id_seq,
                se.location                   AS event_location,
                se.sample_ordinal             AS event_repeat,
                se.date_start                 AS event_date_start,
                se.date_end                   AS event_date_end,
                ses.name                      AS event_status,
                status_se.name                AS event_status_internal,
                se.date_created               AS event_date_created,
                se.date_updated               AS event_date_updated,
                ua_se_o.user_name             AS event_created_by,
                ua_se_u.user_name             AS event_updated_by,
                sed.study_event_definition_id AS study_event_definition_id_seq,
                sed.oc_oid                    AS event_oid,
                sed.name                      AS event_name,
                sed.ordinal                   AS event_order
            FROM
                openclinica_fdw.study_event AS se
                INNER JOIN
                openclinica_fdw.study_event_definition AS sed
                    ON sed.study_event_definition_id = se.study_event_definition_id
                INNER JOIN
                openclinica_fdw.subject_event_status AS ses
                    ON ses.subject_event_status_id = se.subject_event_status_id
                INNER JOIN
                status_filter AS status_se
                    ON se.status_id = status_se.status_id
                INNER JOIN
                user_id_name AS ua_se_o
                    ON se.owner_id = ua_se_o.user_id
                LEFT JOIN
                user_id_name AS ua_se_u
                    ON se.update_id = ua_se_u.user_id
    ), crf_details AS (
            WITH ec_ale_sdv AS (
                    SELECT
                        ale.event_crf_id,
                        max(
                                ale.audit_date) AS audit_date
                    FROM
                        openclinica_fdw.audit_log_event AS ale
                        INNER JOIN
                        openclinica_fdw.audit_log_event_type AS alet
                            ON alet.audit_log_event_type_id =
                            ale.audit_log_event_type_id
                    WHERE
                        ale.event_crf_id IS NOT NULL
                        AND alet.name = $$EventCRF SDV Status$$
                    GROUP BY
                        ale.event_crf_id
            )
            SELECT
                crf.crf_id                     AS crf_id_seq,
                crf.oc_oid                     AS crf_parent_oid,
                crf.name                       AS crf_parent_name,
                cv.crf_version_id              AS crf_version_id_seq,
                cv.oc_oid                      AS crf_version_oid,
                cv.name                        AS crf_version_name,
                ec.event_crf_id                AS event_crf_id_seq,
                ec.study_event_id              AS crf_study_event_id_seq,
                ec.date_interviewed            AS crf_date_interviewed,
                ec.interviewer_name            AS crf_interviewer_name,
                ec.date_completed              AS crf_date_completed,
                ec.date_validate               AS crf_date_validate,
                ua_ec_v.user_name              AS crf_validated_by,
                ec.date_validate_completed     AS crf_date_validate_completed,
                ec.electronic_signature_status AS crf_esignature_status,
                ec.sdv_status                  AS crf_sdv_status,
                ec_ale_sdv.audit_date          AS crf_sdv_status_last_updated,
                ua_ec_s.user_name              AS crf_sdv_status_last_updated_by,
                ec.date_created                AS crf_date_created,
                ec.date_updated                AS crf_date_updated,
                ua_ec_o.user_name              AS crf_created_by,
                ua_ec_u.user_name              AS crf_updated_by,
                CASE
                WHEN ses.name IN
                    ($$stopped$$, $$skipped$$, $$locked$$)
                THEN $$locked$$
                WHEN status_cv.name <> $$available$$
                THEN $$locked$$
                WHEN status_ec.name = $$available$$
                THEN $$initial data entry$$
                WHEN status_ec.name = $$unavailable$$
                THEN
                    CASE
                    WHEN edc.double_entry = TRUE
                    THEN $$validation completed$$
                    WHEN edc.double_entry = FALSE
                    THEN $$data entry complete$$
                    ELSE $$unhandled$$
                    END
                WHEN status_ec.name = $$pending$$
                THEN
                    CASE
                    WHEN ec.validator_id <>
                        0 /* default zero, blank if event_crf created by insertaction */
                    THEN $$double data entry$$
                    WHEN ec.validator_id =
                        0 /* default value present means non-dde run done */
                    THEN $$initial data entry complete$$
                    ELSE $$unhandled$$
                    END
                ELSE status_ec.name
                END                            AS crf_status,
                status_ec.name                 AS crf_status_internal,
                edc.study_id                   AS edc_study_id
            FROM
                openclinica_fdw.event_crf AS ec
                INNER JOIN
                openclinica_fdw.crf_version AS cv
                    ON cv.crf_version_id = ec.crf_version_id
                INNER JOIN
                openclinica_fdw.crf
                    ON crf.crf_id = cv.crf_id
                INNER JOIN
                openclinica_fdw.study_event AS se
                    ON ec.study_event_id = se.study_event_id
                INNER JOIN
                openclinica_fdw.subject_event_status AS ses
                    ON ses.subject_event_status_id = se.subject_event_status_id
                INNER JOIN
                openclinica_fdw.event_definition_crf AS edc
                    ON edc.crf_id = cv.crf_id
                    AND edc.study_event_definition_id =
                        se.study_event_definition_id
                INNER JOIN
                status_filter AS status_ec
                    ON ec.status_id = status_ec.status_id
                INNER JOIN
                status_filter AS status_cv
                    ON cv.status_id = status_cv.status_id
                INNER JOIN
                user_id_name AS ua_ec_o
                    ON ec.owner_id = ua_ec_o.user_id
                LEFT JOIN
                user_id_name AS ua_ec_u
                    ON ec.update_id = ua_ec_u.user_id
                LEFT JOIN
                user_id_name AS ua_ec_v
                    ON ec.validator_id = ua_ec_v.user_id
                LEFT JOIN
                ec_ale_sdv
                    ON ec_ale_sdv.event_crf_id = ec.event_crf_id
                LEFT JOIN
                user_id_name AS ua_ec_s
                    ON ec.sdv_update_id = ua_ec_s.user_id
                    AND ec.sdv_status = TRUE
    )
    SELECT
        study_details.*,
        subject_details.*,
        event_details.*,
        crf_details.*
    FROM
        study_details
        INNER JOIN
        subject_details
            ON subject_details.subject_study_id = study_details.site_id
        INNER JOIN
        event_details
            ON subject_details.study_subject_id_seq =
            event_details.event_study_subject_id_seq
        INNER JOIN
        crf_details
            ON crf_details.crf_study_event_id_seq = event_details.study_event_id_seq
            AND crf_details.edc_study_id = study_details.study_id
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;