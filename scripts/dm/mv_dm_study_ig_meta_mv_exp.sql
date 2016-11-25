CREATE MATERIALIZED VIEW dm.study_ig_meta_mv_exp AS
  /* Expand the set of items to include a row for each multi-value choice. */
  WITH response_sets AS (SELECT * FROM dm.response_sets),
    study_ig_meta_mpv AS (
      SELECT * FROM dm.study_ig_meta_mpv
      WHERE study_ig_meta_mpv.is_multi_choice)
  SELECT DISTINCT ON (mpv_rs.item_id, rs.option_value)
    mpv_rs.item_id,
    mpv_rs.item_oid AS item_oid_multi_original,
    mpv_rs.item_name AS item_name_multi_original,
    mpv_rs.item_data_type_id,
    NULL AS item_data_type_id_multi_original,
    rs.option_order,
    rs.option_value,
    rs.option_text,
    row_number() OVER (
      PARTITION BY
        mpv_rs.item_id
      ORDER BY
        mpv_rs.item_response_set_id,
        rs.option_order
    ) AS item_multi_order_over_rsi,
    mpv_rs.item_response_set_id
  FROM response_sets AS rs
  LEFT JOIN study_ig_meta_mpv AS mpv_rs
    ON mpv_rs.item_response_set_id = rs.response_set_id
       AND mpv_rs.item_response_set_version = rs.version_id
  UNION ALL
  SELECT
    mpv_u.item_id,
    NULL,
    NULL,
    5, /* 5=ST item_data_type */
    mpv_u.item_data_type_id,
    NULL,
    NULL,
    NULL,
    NULL,
    mpv_u.item_response_set_id
  FROM study_ig_meta_mpv AS mpv_u;
