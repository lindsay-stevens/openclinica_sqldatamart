CREATE OR REPLACE VIEW dm.study_ig_clinicaldata AS
  WITH study_ig_clinicaldata_multi_reagg AS (
    SELECT *
    FROM dm.study_ig_clinicaldata_multi_reagg),
      response_sets AS (
      SELECT *
      FROM dm.response_sets),
      event_definition_crf AS (
      SELECT *
      FROM openclinica_fdw.event_definition_crf
      WHERE
        event_definition_crf.parent_id IS
        NULL /* study-level definitions only. */)

  SELECT
    /* ids for further joins */
    mstudy.study_id,
    ss.study_subject_id,
    se.study_event_id,
    ec.event_crf_id,
    ig.item_group_id,
    i.item_id,
    coalesce(
      response_sets.response_set_id,
      multi_split.response_set_id) AS response_set_id,
    id.item_data_id,
    multi_split.item_multi_order_over_rsi,

    /* columns for item group rows */
    mstudy.study_oid,
    mstudy.study_name,
    msite.site_oid,
    msite.site_name,
    ss.oc_oid AS subject_oid,
    ss.label AS subject_id,
    sed.oc_oid AS event_oid,
    sed.name AS event_name,
    sed.ordinal AS event_order,
    se.sample_ordinal AS event_repeat,
    crf.name AS crf_parent_name,
    cv.name AS crf_version,
    cv.oc_oid AS crf_version_oid,
    openclinica_fdw.dm_determine_crf_status(
      se.subject_event_status_id, cv.status_id, ec.status_id, ec_status.name,
      ec.validator_id, edc.double_entry) AS crf_status,
    ig.oc_oid AS item_group_oid,
    id.ordinal AS item_group_repeat,
    (openclinica_fdw.dm_clean_try_cast_value(
      coalesce(multi_split.item_data_type_id, i.item_data_type_id),
      coalesce(multi_split.item_value, id.value))).*,
    coalesce(
      response_sets.option_text, multi_split.option_text) AS item_value_label,
    i.item_data_type_id,
    id.value AS item_value_original
  FROM openclinica_fdw.study_subject AS ss
  LEFT JOIN dm.metadata_site AS msite
    ON msite.site_id = ss.study_id
  LEFT JOIN dm.metadata_study AS mstudy
    ON mstudy.study_id = msite.site_parent_study_id
       OR mstudy.study_id = ss.study_id
  INNER JOIN openclinica_fdw.study_event AS se
    ON se.study_subject_id = ss.study_subject_id
  INNER JOIN openclinica_fdw.study_event_definition AS sed
    ON sed.study_event_definition_id = se.study_event_definition_id
  INNER JOIN event_definition_crf AS edc
    ON edc.study_event_definition_id = se.study_event_definition_id
  INNER JOIN openclinica_fdw.event_crf AS ec
    ON se.study_event_id = ec.study_event_id
  --AND ec.study_subject_id = ss.study_subject_id
  INNER JOIN openclinica_fdw.status AS ec_status
    ON ec.status_id = ec_status.status_id
  INNER JOIN openclinica_fdw.crf_version AS cv
    ON cv.crf_version_id = ec.crf_version_id
       AND cv.crf_id = edc.crf_id
  INNER JOIN openclinica_fdw.crf
    ON crf.crf_id = cv.crf_id
       AND crf.crf_id = edc.crf_id
  INNER JOIN openclinica_fdw.item_group AS ig
    ON ig.crf_id = cv.crf_id
  INNER JOIN openclinica_fdw.item_group_metadata AS igm
    ON igm.item_group_id = ig.item_group_id
       AND igm.crf_version_id = cv.crf_version_id
  INNER JOIN openclinica_fdw.item_form_metadata AS ifm
    ON cv.crf_version_id = ifm.crf_version_id
  INNER JOIN openclinica_fdw.item AS i
    ON i.item_id = ifm.item_id
       AND i.item_id = igm.item_id
  INNER JOIN openclinica_fdw.item_data AS id
    ON id.item_id = i.item_id
       AND id.event_crf_id = ec.event_crf_id
  LEFT JOIN study_ig_clinicaldata_multi_reagg AS multi_split
    ON multi_split.item_data_id = id.item_data_id
  LEFT JOIN response_sets
    ON response_sets.response_set_id = ifm.response_set_id
       AND response_sets.version_id = ifm.crf_version_id
       AND response_sets.option_value = id.value
  WHERE

    id.value != $$$$
    AND id.status_id NOT IN (5, 7) /* 5=removed, 7=auto-removed. */

