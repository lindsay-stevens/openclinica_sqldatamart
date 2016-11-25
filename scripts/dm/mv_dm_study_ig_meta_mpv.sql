CREATE MATERIALIZED VIEW dm.study_ig_meta_mpv AS
SELECT *,
    row_number() OVER (
      PARTITION BY s.item_group_id
      ORDER BY s.item_id) AS item_ordinal_per_ig_over_crfv
FROM (
  SELECT DISTINCT ON (
    igm.item_group_id,
    igm.item_id
  )
    study.study_id,
    igm.crf_version_id,
    ig.item_group_id,
    i.item_id AS item_id,
    i.oc_oid AS item_oid,
    i.name AS item_name,
    openclinica_fdw.dm_clean_name_string(
      CASE
        WHEN left(i.name, 1) ~ $r$[0-9]$r$
          THEN concat($s$_$s$, i.name)
        ELSE i.name
      END) AS item_name_clean,
    i.description AS item_description,
    i.item_data_type_id,
    rs.is_multi_choice,
    rs.is_single_choice,
    rs.response_set_id AS item_response_set_id,
    rs.version_id AS item_response_set_version
  FROM openclinica_fdw.study
    INNER JOIN openclinica_fdw.study_event_definition AS sed
      ON sed.study_id = study.study_id
    INNER JOIN openclinica_fdw.event_definition_crf AS edc
      ON edc.study_event_definition_id = sed.study_event_definition_id
    INNER JOIN openclinica_fdw.crf_version AS cv
      ON cv.crf_id = edc.crf_id
    INNER JOIN openclinica_fdw.item_group AS ig
      ON ig.crf_id = cv.crf_id
    INNER JOIN openclinica_fdw.item_group_metadata AS igm
      ON igm.item_group_id = ig.item_group_id
      AND igm.crf_version_id = cv.crf_version_id
    INNER JOIN openclinica_fdw.item_form_metadata AS ifm
      ON cv.crf_version_id = ifm.crf_version_id
    INNER JOIN dm.response_sets AS rs
      ON rs.response_set_id = ifm.response_set_id
      AND rs.version_id = ifm.crf_version_id
    INNER JOIN openclinica_fdw.item AS i
      ON i.item_id = ifm.item_id
      AND i.item_id = igm.item_id
  WHERE
    study.parent_study_id IS NULL
    AND study.status_id NOT IN (5, 7) /* removed, auto-removed */
    AND edc.status_id NOT IN (5, 7)
  ORDER BY
    igm.item_group_id,
    igm.item_id,
    igm.crf_version_id
) AS s;