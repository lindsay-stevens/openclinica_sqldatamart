CREATE MATERIALIZED VIEW dm.metadata_pre_view AS
SELECT
  study.*,
  sed.study_event_definition_id AS event_id,
  sed.oc_oid AS event_oid,
  sed.ordinal AS event_order,
  sed.name AS event_name,
  sed.date_created AS event_date_created,
  sed.date_updated AS event_date_updated,
  sed.repeating AS event_repeating,
  crf.oc_oid AS crf_parent_oid,
  crf.name AS crf_parent_name,
  crf.date_created AS crf_parent_date_created,
  crf.date_updated AS crf_parent_date_updated,
  cv.name AS crf_version,
  cv.crf_version_id AS crf_version_id,
  cv.oc_oid AS crf_version_oid,
  cv.date_created AS crf_version_date_created,
  cv.date_updated AS crf_version_date_updated,
  edc.required_crf AS crf_is_required,
  edc.double_entry AS crf_is_double_entry,
  edc.hide_crf AS crf_is_hidden,
  edc.null_values AS crf_null_values,
  sct.label AS crf_section_label,
  sct.title AS crf_section_title,
  ig.item_group_id AS item_group_id,
  ig.oc_oid AS item_group_oid,
  ig.name AS item_group_name,
  ifm.ordinal AS item_form_order,
  i.item_id AS item_id,
  iiooc.item_ordinal_per_ig_over_crfv,
  i.oc_oid AS item_oid,
  i.name AS item_name,
  openclinica_fdw.dm_clean_name_string(
    CASE
      WHEN left(i.name, 1) ~ $r$[0-9]$r$
        THEN concat($s$_$s$, i.name)
      ELSE i.name
    END) AS item_name_clean,
  i.description AS item_description,
  i.units AS item_units,
  i.item_data_type_id,
  idt.code AS item_data_type,
  rt.name AS item_response_type,
  rt.name IN ($s$multi-select$s$, $s$checkbox$s$) AS is_multi_choice,
  CASE
    WHEN rs.label IN ($s$text$s$, $s$textarea$s$)
      THEN NULL
    ELSE rs.label
  END AS item_response_set_label,
  rs.response_set_id AS item_response_set_id,
  rs.version_id AS item_response_set_version,
  ifm.question_number_label AS item_question_number,
  ifm.header AS item_header,
  ifm.subheader AS item_subheader,
  ifm.left_item_text AS item_left_item_text,
  ifm.right_item_text AS item_right_item_text,
  ifm.regexp AS item_regexp,
  ifm.regexp_error_msg AS item_regexp_error_msg,
  ifm.required AS item_required,
  ifm.default_value AS item_default_value,
  ifm.response_layout AS item_response_layout,
  ifm.width_decimal AS item_width_decimal,
  ifm.show_item AS item_show_item,
  sim.item_oid AS item_scd_item_oid,
  sim.option_value AS item_scd_item_option_value,
  sim.option_text AS item_scd_item_option_text,
  sim.message AS item_scd_validation_message
FROM dm.metadata_study AS study
  INNER JOIN openclinica_fdw.study_event_definition AS sed
    ON sed.study_id = study.study_id
  INNER JOIN openclinica_fdw.event_definition_crf AS edc
    ON edc.study_event_definition_id = sed.study_event_definition_id
  INNER JOIN openclinica_fdw.crf_version AS cv
    ON cv.crf_id = edc.crf_id
  INNER JOIN openclinica_fdw.crf
    ON crf.crf_id = cv.crf_id
    AND crf.crf_id = edc.crf_id
  INNER JOIN openclinica_fdw.item_group AS ig
    ON ig.crf_id = crf.crf_id
  INNER JOIN openclinica_fdw.item_group_metadata AS igm
    ON igm.item_group_id = ig.item_group_id
    AND igm.crf_version_id = cv.crf_version_id
  INNER JOIN openclinica_fdw.item_form_metadata AS ifm
    ON cv.crf_version_id = ifm.crf_version_id
  INNER JOIN openclinica_fdw."section" AS sct
    ON sct.crf_version_id = cv.crf_version_id
    AND sct.section_id = ifm.section_id
  INNER JOIN openclinica_fdw.response_set AS rs
    ON rs.response_set_id = ifm.response_set_id
    AND rs.version_id = ifm.crf_version_id
  INNER JOIN openclinica_fdw.response_type AS rt
    ON rs.response_type_id = rt.response_type_id
  INNER JOIN openclinica_fdw.item AS i
    ON i.item_id = ifm.item_id
    AND i.item_id = igm.item_id
  INNER JOIN (
    SELECT
    item_by_ig_distinct.item_id,
    row_number() OVER (
      PARTITION BY item_by_ig_distinct.item_group_id
      ORDER BY item_by_ig_distinct.item_id) AS item_ordinal_per_ig_over_crfv
    FROM (
      SELECT DISTINCT ON (
        igm.item_group_id,
        igm.item_id
      )
        igm.item_group_id,
        igm.item_id
      FROM openclinica_fdw.item_group_metadata AS igm
      ORDER BY
        igm.item_group_id,
        igm.item_id,
        igm.crf_version_id
    ) AS item_by_ig_distinct
  ) AS iiooc
    ON iiooc.item_id = i.item_id
  INNER JOIN openclinica_fdw.item_data_type AS idt
    ON idt.item_data_type_id = i.item_data_type_id
  LEFT JOIN
  (
    SELECT
      sim.scd_item_form_metadata_id,
      sim.control_item_form_metadata_id,
      sim.message,
      i.oc_oid AS item_oid,
      i.status_id,
      sim.option_value,
      response_sets.option_text
    FROM openclinica_fdw.scd_item_metadata AS sim
    INNER JOIN openclinica_fdw.item_form_metadata AS ifm
      ON ifm.item_form_metadata_id = sim.control_item_form_metadata_id
      INNER JOIN openclinica_fdw.item AS i
        ON ifm.item_id = i.item_id
      LEFT JOIN dm.response_sets
        ON ifm.response_set_id = response_sets.response_set_id
        AND ifm.crf_version_id = response_sets.version_id
        AND sim.option_value = response_sets.option_value) AS sim
    ON ifm.item_form_metadata_id = sim.scd_item_form_metadata_id
WHERE
  edc.parent_id IS NULL
  AND edc.status_id NOT IN (5, 7) /* removed or auto-removed */;