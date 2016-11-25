CREATE MATERIALIZED VIEW dm.study_ig_metadata AS
  /*
  Build all possible item identifier strings for item group views.

  Item group bucket divides the columns in each group into buckets, 200 each, so
  that the columns are distributed without exceeding relation width limits. This
  column count is added to by a few row headers in the item group tables.
  */
  WITH study_ig_meta_mpv AS (
    SELECT *
    FROM dm.study_ig_meta_mpv AS simm),
      study_ig_meta_mv_exp AS (
      SELECT *
      FROM dm.study_ig_meta_mv_exp)
  SELECT
    mpv.study_id,
    mpv.crf_version_id,
    mpv.item_group_id,
    mpv.item_id,
    mpv.item_ordinal_per_ig_over_crfv,
    lower(
      concat_ws(
        $s$_$s$,
        mpv.item_oid,
        openclinica_fdw.dm_clean_name_string(mpv_exp.option_value)
      )) AS item_oid,
    /* e.g. i_group_my_second_item_choice_3 */
    lower(
      concat_ws(
        $s$_$s$,
        mpv.item_name,
        openclinica_fdw.dm_clean_name_string(mpv_exp.option_value)
      )) AS item_name,
    /* e.g. my_second_item_choice_3 */
    mpv.item_name_clean,
    mpv.item_description,
    lower(
      concat_ws(
        $s$_$s$,
        left(mpv.item_name_clean, 12),
        openclinica_fdw.dm_clean_name_string(mpv_exp.option_value),
        left(openclinica_fdw.dm_clean_name_string(mpv.item_description), 45)
      )) AS item_ident_mvalue_description,
    /* e.g. my_second_it_choice_3_my_2nd_item */
    lower(
      concat_ws(
        $s$_$s$,
        left(mpv.item_name_clean, 12),
        openclinica_fdw.dm_clean_name_string(mpv_exp.option_value)
      )) AS item_ident_mvalue,
    /* e.g. my_second_it_choice_3 */
    lower(
      concat_ws(
        $s$_$s$,
        left(mpv.item_name_clean, 12),
        mpv.item_ordinal_per_ig_over_crfv,
        mpv_exp.item_multi_order_over_rsi
      )) AS item_ident_itemid_morderid,
    /* e.g. my_second_it_2_3 */
    lower(
      concat_ws(
        $s$_m_$s$,
        concat($s$i_$s$, mpv.item_ordinal_per_ig_over_crfv),
        mpv_exp.item_multi_order_over_rsi
      )) AS item_ident_last_ditch,
    /* e.g. i_123_m_2 */
    mpv_exp.item_data_type_id_multi_original,
    coalesce(
      mpv_exp.item_data_type_id,
      mpv.item_data_type_id) AS item_data_type_id,
    mpv.item_response_set_id,
    mpv.is_multi_choice,
    mpv.is_single_choice,
    mpv_exp.item_oid_multi_original,
    mpv_exp.item_name_multi_original,
    mpv_exp.option_order AS item_multi_option_order,
    mpv_exp.option_value AS item_multi_option_value,
    mpv_exp.option_text AS item_multi_option_text,
    mpv_exp.item_multi_order_over_rsi
  FROM study_ig_meta_mpv AS mpv
  LEFT JOIN study_ig_meta_mv_exp AS mpv_exp
    ON mpv.item_id = mpv_exp.item_id;