CREATE OR REPLACE VIEW dm.study_ig_clinicaldata_multi_reagg AS
/* Gather up the labels matching multi-choice item values.

Query plan optimisations:
- Append / Union faster than 2 joins,
- Materializing with CTE faster than subquery.
*/
  WITH study_ig_clinicaldata_multi_split AS (
    SELECT *
    FROM dm.study_ig_clinicaldata_multi_split)

  SELECT
    sicms.item_data_id,
    sicms.response_set_id,
    sicms.item_value,
    sicms.option_text,
    TRUE AS is_split_row,
    sicms.item_multi_order_over_rsi,
    sicms.item_data_type_id
  FROM study_ig_clinicaldata_multi_split AS sicms
  UNION ALL
  SELECT
    sicms_u.item_data_id,
    sicms_u.response_set_id,
    sicms_u.item_value_original,
    string_agg(sicms_u.option_text, $s$,$s$
    ORDER BY item_multi_order_over_rsi),
    FALSE,
    NULL,
    5
  FROM study_ig_clinicaldata_multi_split AS sicms_u
  GROUP BY
    sicms_u.item_data_id,
    sicms_u.response_set_id,
    sicms_u.item_value_original,
    sicms_u.item_data_type_id
