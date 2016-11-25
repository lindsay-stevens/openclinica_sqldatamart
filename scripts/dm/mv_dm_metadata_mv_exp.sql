CREATE MATERIALIZED VIEW dm.metadata_mv_exp AS
  /* Expand the set of items to include a row for each multi-value choice. */
  SELECT DISTINCT ON (mpv_rs.item_id, rs.option_value)
    mpv_rs.item_id,
    mpv_rs.item_oid AS item_oid_multi_original,
    mpv_rs.item_name AS item_name_multi_original,
    mpv_rs.item_data_type,
    NULL AS item_data_type_multi_original,
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
  FROM dm.response_sets AS rs
  LEFT JOIN dm.metadata_pre_view AS mpv_rs
    ON mpv_rs.item_response_set_id = rs.response_set_id
       AND mpv_rs.item_response_set_version = rs.version_id
  WHERE mpv_rs.is_multi_choice
  UNION ALL
  SELECT
    mpv_u.item_id,
    NULL,
    NULL,
    $s$ST$s$,
    mpv_u.item_data_type,
    NULL,
    NULL,
    NULL,
    NULL,
    mpv_u.item_response_set_id
  FROM dm.metadata_pre_view AS mpv_u
  WHERE mpv_u.is_multi_choice;