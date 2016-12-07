CREATE OR REPLACE VIEW dm.study_ig_viewdefs AS
  /* Build the item group view definitions. */
  WITH met AS (
    SELECT
      *,
      lower(
        CASE
        WHEN t.ig_viewtype = 'av_'
          THEN study_ig_item_identifiers.av_ident_final
        ELSE study_ig_item_identifiers.mv_ident_final
        END) AS ident_final
    FROM
    dm.study_ig_item_identifiers, (VALUES ('av'), ('mv')) AS t(ig_viewtype)
  ), format_strings AS (
    SELECT
      $f$ CREATE OR REPLACE VIEW %1$I.%2$I AS
            WITH study_ig_clinicaldata AS (
              SELECT
                sic.study_name,
                sic.site_oid,
                sic.site_name,
                sic.subject_id,
                sic.event_oid,
                sic.event_name,
                sic.event_order,
                sic.event_repeat,
                sic.crf_parent_name,
                sic.crf_version,
                sic.crf_version_oid,
                sic.crf_status,
                sic.item_group_oid,
                sic.item_group_repeat,
                sic.item_id,
                sic.data_text,
                sic.data_numeric,
                sic.data_date,
                sic.cast_failure,
                sic.item_multi_order_over_rsi,
                sic.item_value_label,
                siii.av_ident_final
              FROM dm.study_ig_clinicaldata AS sic
              INNER JOIN dm.study_ig_item_identifiers AS siii
                ON siii.item_id = sic.item_id
              WHERE
                sic.study_id = %3$s
                AND sic.item_group_id = %4$s
              OFFSET 0)
            SELECT
              study_name,
              site_oid,
              site_name,
              subject_id,
              event_oid,
              event_name,
              event_order,
              event_repeat,
              crf_parent_name,
              crf_version,
              crf_version_oid,
              crf_status,
              item_group_oid,
              item_group_repeat,
              jsonb_object_agg(av_ident_final, data_text)
                FILTER (WHERE cast_failure IS NOT NULL) AS cast_failures,
            %5$s %6$s $f$ :: TEXT AS group_header,
      $f$ FROM study_ig_clinicaldata
          GROUP BY
            study_name, site_oid, site_name, subject_id, event_oid, event_name,
            event_order, event_repeat, crf_parent_name, crf_version,
            crf_version_oid, crf_status, item_group_oid,
            item_group_repeat; $f$ :: TEXT AS group_footer,
      $f$ max(
            CASE
              WHEN item_id=%1$s AND item_multi_order_over_rsi %2$s
                THEN %3$s
            END) as %4$I $f$ :: TEXT AS item_data_column,
      $f$ max(
            CASE
              WHEN item_id=%1$s AND item_multi_order_over_rsi %2$s
                THEN item_value_label
            END) as %3$I $f$ :: TEXT AS item_label_column
  )

  SELECT
    format(
      (SELECT group_header
       FROM format_strings),
      ddl.study_name_clean,
      lower(
        CASE
        WHEN ig_viewtype = 'av'
          THEN concat($s$av_$s$, ddl.item_group_oid_bucket)
        ELSE ddl.item_group_oid_bucket
        END),
      ddl.study_id,
      ddl.item_group_id,
      array_to_string(
        array_agg(ddl.column_def
        ORDER BY
          ddl.study_name_clean,
          ddl.item_group_id,
          ddl.item_ordinal_per_ig_over_crfv,
          ddl.item_multi_order_over_rsi NULLS FIRST), chr(44)),
      (SELECT group_footer
       FROM format_strings)
    ) AS create_statement,
    ddl.ig_viewtype,
    ddl.item_group_oid,
    ddl.study_name_clean,
    ddl.item_group_oid_bucket
  FROM
    (
      SELECT
        CASE
        WHEN bucket.item_group_bucket > 1
          THEN concat_ws(
            $s$_p$s$, bucket.item_group_oid, bucket.item_group_bucket)
        ELSE bucket.item_group_oid
        END AS item_group_oid_bucket,
        bucket.*
      FROM
        (
          SELECT
            width_bucket(
              row_number() OVER (
                PARTITION BY
                  cols.ig_viewtype,
                  cols.item_group_id
                ORDER BY
                  cols.item_ordinal_per_ig_over_crfv,
                  cols.item_multi_order_over_rsi),
              0,
              200000,
              1000) AS item_group_bucket,
            cols.*
          FROM
            (
              SELECT
                met.ig_viewtype,
                met.study_id,
                met.study_name_clean,
                met.item_group_id,
                met.item_group_oid,
                met.item_ordinal_per_ig_over_crfv,
                met.item_multi_order_over_rsi,
                1 AS column_sequence,
                format(
                  (SELECT item_data_column
                   FROM format_strings),
                  met.item_id,
                  CASE
                  WHEN met.item_multi_order_over_rsi IS NULL
                    THEN $s$ IS NULL $s$
                  ELSE concat(
                    $s$ = $s$,
                    met.item_multi_order_over_rsi)
                  END,
                  CASE /* 6=INT, 7=REAL */
                  WHEN met.item_data_type_id IN (6, 7)
                    THEN $s$ data_numeric $s$
                  WHEN met.item_data_type_id = 9 /* 9=DATE */
                    THEN $s$ data_date $s$
                  ELSE $s$ data_text $s$
                  END,
                  met.ident_final) AS column_def
              FROM met
              UNION ALL
              SELECT
                met.ig_viewtype,
                met.study_id,
                met.study_name_clean,
                met.item_group_id,
                met.item_group_oid,
                met.item_ordinal_per_ig_over_crfv,
                met.item_multi_order_over_rsi,
                2,
                format(
                  (SELECT item_label_column
                   FROM format_strings),
                  met.item_id,
                  CASE
                  WHEN met.item_multi_order_over_rsi IS NULL
                    THEN $s$ IS NULL $s$
                  ELSE concat(
                    $s$ = $s$,
                    met.item_multi_order_over_rsi)
                  END,
                  concat(met.ident_final, $s$_label$s$))
              FROM met
              WHERE met.is_single_choice OR met.is_multi_choice
            ) AS cols
          ORDER BY
            cols.study_id,
            cols.item_group_id,
            cols.item_ordinal_per_ig_over_crfv,
            cols.item_multi_order_over_rsi,
            cols.column_sequence
        ) AS bucket
    ) AS ddl
  GROUP BY
    ddl.study_id,
    ddl.study_name_clean,
    ddl.ig_viewtype,
    ddl.item_group_oid_bucket,
    ddl.item_group_oid,
    ddl.item_group_id
