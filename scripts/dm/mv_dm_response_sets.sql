CREATE MATERIALIZED VIEW dm.response_sets AS
  SELECT
    rsj.version_id,
    rsj.response_set_id,
    rsj.response_type_id,
    rsj.label,
    trim(
      BOTH FROM (
        rs_arrays_orders.array_val [
        rs_arrays_orders.option_order])) AS option_value,
    replace(
      trim(
        BOTH FROM (
          rs_arrays_orders.array_text [
          rs_arrays_orders.option_order])),
      $$##@##@##$$, $$,$$) AS option_text,
    rs_arrays_orders.option_order,
    rsj.response_type_id IN (3, 7) AS is_multi_choice, /* checkbox, multi-select */
    rsj.response_type_id IN (5, 6) AS is_single_choice /* radio, single-select */
  FROM
  (
    SELECT
      rs_arrays.response_set_id,
      rs_arrays.array_val,
      rs_arrays.array_text,
      generate_subscripts(rs_arrays.array_val, 1) AS option_order
    FROM
      (
        SELECT
          rs.response_set_id,
          string_to_array(
            rs.options_values, $$,$$) AS array_val,
          string_to_array(
            rs.option_text, $$,$$) AS array_text
        FROM
          (
            SELECT
              rs_rep.response_set_id,
              rs_rep.options_values,
              /* postgres' regex can't separate \, from , */
              /* so temporarily replace with an unlikely string. */
              replace(
                rs_rep.options_text, $$\,$$, $$##@##@##$$) AS option_text
            FROM openclinica_fdw.response_set AS rs_rep
            /* 3=checkbox, 5=radio, 6=single-select, 7=multi-select */
            WHERE response_type_id IN (3, 5, 6, 7)
          ) AS rs
      ) AS rs_arrays
  ) AS rs_arrays_orders
  INNER JOIN openclinica_fdw.response_set AS rsj
    ON rsj.response_set_id = rs_arrays_orders.response_set_id;