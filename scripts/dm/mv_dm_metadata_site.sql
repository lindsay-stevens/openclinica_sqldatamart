CREATE MATERIALIZED VIEW dm.metadata_site AS
  SELECT
    study.study_id AS site_id,
    study.name AS site_name,
    openclinica_fdw.dm_clean_name_string(study.oc_oid) AS site_name_clean,
    study.oc_oid AS site_oid,
    study.unique_identifier AS site_unique_identifier,
    status.name AS site_status,
    study.date_created AS site_date_created,
    study.date_updated AS site_date_updated,
    study.parent_study_id AS site_parent_study_id
  FROM openclinica_fdw.study
  LEFT JOIN openclinica_fdw.status
    ON status.status_id = study.status_id
  WHERE
    study.status_id NOT IN (5, 7)
    AND study.parent_study_id IS NOT NULL;;