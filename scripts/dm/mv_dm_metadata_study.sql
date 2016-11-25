CREATE MATERIALIZED VIEW dm.metadata_study AS
  SELECT
    study.study_id,
    study.name AS study_name,
    openclinica_fdw.dm_clean_name_string(study.oc_oid) AS study_name_clean,
    study.oc_oid AS study_oid,
    study.unique_identifier AS study_unique_identifier,
    status.name AS study_status,
    study.date_created AS study_date_created,
    study.date_updated AS study_date_updated,
    study.parent_study_id AS study_parent_study_id
  FROM openclinica_fdw.study
  LEFT JOIN openclinica_fdw.status
    ON status.status_id = study.status_id
  WHERE
    study.status_id NOT IN (5, 7)
    AND study.parent_study_id IS NULL;