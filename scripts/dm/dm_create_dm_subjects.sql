CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subjects()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subjects AS
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
    )
    SELECT
        study_details.*,
        subject_details.*
    FROM
        study_details
        INNER JOIN
        subject_details
            ON subject_details.subject_study_id = study_details.site_id
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;