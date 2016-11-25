CREATE OR REPLACE VIEW dm.study_id_ident_rejoin AS
  /* Get the final identifiers used in item groups and join back to metadata. */

  SELECT
    ms.study_name_clean AS nspname,
    lower(siii.item_group_oid) AS item_group_oid,
    concat($s$av_$s$, lower(siii.item_group_oid)) AS item_group_relname,
    siii.av_ident_final,
    siii.mv_ident_final,
    openclinica_fdw.dm_clean_name_string(
      sim.item_description) AS clean_description,
    sim.item_data_type_id,
    sim.item_multi_option_value,
    openclinica_fdw.dm_clean_name_string(
      sim.item_multi_option_text) AS clean_item_multi_option_text,
    sim.item_response_set_id,
    sim.crf_version_id,
    sim.item_id,
    sim.item_group_id
  FROM dm.metadata_study AS ms
  INNER JOIN dm.study_ig_item_identifiers AS siii
    ON siii.study_id = ms.study_id
  INNER JOIN dm.study_ig_metadata AS sim
    ON sim.item_oid = siii.item_oid
  ORDER BY
    siii.study_id,
    siii.item_group_id,
    siii.item_ordinal_per_ig_over_crfv,
    siii.item_multi_order_over_rsi NULLS FIRST
