CREATE OR REPLACE VIEW dm.study_ig_clinicaldata_multi_split AS
  WITH study_ig_meta_mv_exp AS (
    SELECT *
    FROM dm.study_ig_meta_mv_exp),
      response_sets AS (
      SELECT *
      FROM dm.response_sets
      WHERE /* checkbox, multi-select */
        response_sets.response_type_id IN (3, 7))
  SELECT
    split.item_id,
    split.event_crf_id,
    split.item_data_id,
    rs.response_set_id,
    split.item_value,
    rs.option_text,
    simme.item_multi_order_over_rsi,
    split.item_value_original,
    simme.item_data_type_id
  FROM (
         SELECT
           id.item_id,
           id.event_crf_id,
           id.item_data_id,
           regexp_split_to_table(id.value, $$,$$) AS item_value,
           id.value AS item_value_original
         FROM openclinica_fdw.item_data AS id
         WHERE id.value != $$$$
               /* 5=removed, 7=auto-removed. */
               AND id.status_id NOT IN (5, 7)
       ) AS split
  INNER JOIN openclinica_fdw.event_crf AS ec
    ON ec.event_crf_id = split.event_crf_id
  INNER JOIN openclinica_fdw.item_form_metadata AS ifm
    ON ifm.crf_version_id = ec.crf_version_id
       AND ifm.item_id = split.item_id
  INNER JOIN response_sets AS rs
    ON rs.response_set_id = ifm.response_set_id
       AND rs.version_id = ifm.crf_version_id
       AND rs.option_value = split.item_value
  INNER JOIN study_ig_meta_mv_exp AS simme
    ON simme.item_id = split.item_id
       AND simme.option_value = split.item_value

