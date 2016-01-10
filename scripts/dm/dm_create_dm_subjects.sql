CREATE OR REPLACE FUNCTION dm_create_dm_subjects()
    RETURNS VOID AS
    $BODY$
    BEGIN
        EXECUTE $query$
CREATE MATERIALIZED VIEW dm.subjects AS
SELECT
  COALESCE(
    parents.name, 
    study.name, 
    'no parent study'
  )                             AS study_name,
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
  ua_ss_o.user_name             AS subject_owned_by_user,
  ua_ss_u.user_name             AS subject_last_updated_by_user
FROM openclinica_fdw.study
LEFT JOIN (
  SELECT study.*
  FROM openclinica_fdw.study
  WHERE study.status_id NOT IN (5, 7) /*removed, auto-removed*/
) AS parents
  ON parents.study_id = study.parent_study_id
INNER JOIN openclinica_fdw.study_subject AS ss
  ON ss.study_id = study.study_id
INNER JOIN openclinica_fdw.subject AS sub
  ON sub.subject_id = ss.subject_id
LEFT JOIN openclinica_fdw.user_account AS ua_ss_o
  ON ua_ss_o.user_id = ss.owner_id
LEFT JOIN openclinica_fdw.user_account AS ua_ss_u
  ON ua_ss_u.user_id = ss.update_id
WHERE
  study.status_id NOT IN (5, 7) --removed, auto-removed
  AND ss.status_id NOT IN (5, 7)

                $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;