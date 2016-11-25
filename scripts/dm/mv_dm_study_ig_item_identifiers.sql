CREATE MATERIALIZED VIEW dm.study_ig_item_identifiers AS
/* Determines the column names to be used for building the item group views. */
WITH study_ig_metadata AS (
  SELECT *
  FROM dm.study_ig_metadata
)
SELECT
  base_ident.study_id,
  ms.study_name_clean,
  base_ident.item_group_id,
  ig.oc_oid AS item_group_oid,
  base_ident.item_ordinal_per_ig_over_crfv,
  base_ident.item_multi_order_over_rsi,
  base_ident.is_multi_choice,
  base_ident.is_single_choice,
  base_ident.item_id,
  base_ident.item_oid,
  base_ident.item_data_type_id,
  base_ident.crf_version_id,
  CASE
    WHEN count(mv_ident_base) OVER w_mv_ident_base = 1
      THEN mv_ident_base
    ELSE
      CASE
        WHEN count(mv_ident_backup_1) OVER w_mv_ident_backup_1 = 1
          THEN mv_ident_backup_1
        ELSE
          CASE
            WHEN count(mv_ident_backup_2) OVER w_mv_ident_backup_2 = 1
              THEN mv_ident_backup_2
            ELSE item_ident_last_ditch
          END
      END
  END AS mv_ident_final,
  CASE
    WHEN count(av_ident_base) OVER w_av_ident_base = 1
      THEN av_ident_base
    ELSE
      CASE
        WHEN count(av_ident_backup_1) OVER w_av_ident_backup_1 = 1
          THEN av_ident_backup_1
        ELSE
          CASE
            WHEN count(av_ident_backup_2) OVER w_av_ident_backup_2 = 1
              THEN av_ident_backup_2
            ELSE item_ident_last_ditch
          END
      END
  END AS av_ident_final
FROM (
  /* Distinct to remove rows added by joining to CRF version. */
  SELECT DISTINCT ON (
    mcii_trim.study_id,
    mcii_trim.item_group_id,
    mcii_trim.item_ordinal_per_ig_over_crfv,
    mcii_trim.item_multi_order_over_rsi
  )
    mcii_trim.study_id,
    mcii_trim.crf_version_id,
    mcii_trim.item_group_id,
    mcii_trim.item_ordinal_per_ig_over_crfv,
    mcii_trim.item_multi_order_over_rsi,
    mcii_trim.is_multi_choice,
    mcii_trim.is_single_choice,
    mcii_trim.item_id,
    mcii_trim.item_oid,
    mcii_trim.item_data_type_id,
    /* Decide if we are going to start with item_oid, or a hint name. */
    CASE
      WHEN which_base.use_item_oid
        THEN left(mcii_trim.item_oid, which_base.mv_trim)
      ELSE left(mcii_trim.item_ident_mvalue_description, which_base.mv_trim)
    END AS mv_ident_base,
    left(mcii_trim.item_ident_mvalue, which_base.mv_trim) AS mv_ident_backup_1,
    left(mcii_trim.item_ident_itemid_morderid, which_base.mv_trim) AS mv_ident_backup_2,
    left(mcii_trim.item_name, which_base.av_trim) AS av_ident_base,
    left(mcii_trim.item_ident_mvalue, which_base.av_trim) AS av_ident_backup_1,
    left(mcii_trim.item_ident_itemid_morderid, which_base.av_trim) AS av_ident_backup_2,
    mcii_trim.item_ident_last_ditch
  FROM study_ig_metadata AS mcii_trim
  INNER JOIN (
    SELECT
      mcii_max_calc_sub.study_id,
      max(length(mcii_max_calc_sub.item_name)) > 12 AS use_item_oid,
      /* mv = main views (for postgres, access) */
      63 AS mv_trim,
      /* av = alias views (for stata, sas) */
      32 AS av_trim
    FROM study_ig_metadata AS mcii_max_calc_sub
    GROUP BY mcii_max_calc_sub.study_id
  ) AS which_base
    ON which_base.study_id = mcii_trim.study_id
  ORDER BY
    mcii_trim.study_id,
    mcii_trim.item_group_id,
    mcii_trim.item_ordinal_per_ig_over_crfv,
    mcii_trim.item_multi_order_over_rsi,
    mcii_trim.crf_version_id
) AS base_ident
INNER JOIN dm.metadata_study AS ms
  ON ms.study_id = base_ident.study_id
INNER JOIN openclinica_fdw.item_group AS ig
  ON ig.item_group_id = base_ident.item_group_id
GROUP BY
  base_ident.study_id,
  base_ident.item_group_id,
  base_ident.item_ordinal_per_ig_over_crfv,
  base_ident.item_multi_order_over_rsi,
  base_ident.is_multi_choice,
  base_ident.is_single_choice,
  base_ident.item_id,
  base_ident.item_oid,
  base_ident.item_data_type_id,
  base_ident.mv_ident_base,
  base_ident.mv_ident_backup_1,
  base_ident.mv_ident_backup_2,
  base_ident.av_ident_base,
  base_ident.av_ident_backup_1,
  base_ident.av_ident_backup_2,
  base_ident.item_ident_last_ditch,
  ms.study_name_clean,
  ig.oc_oid,
  base_ident.crf_version_id
WINDOW
  w_mv_ident_base AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.mv_ident_base
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi),
  w_mv_ident_backup_1 AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.mv_ident_backup_1
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi),
  w_mv_ident_backup_2 AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.mv_ident_backup_2
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi),
  w_av_ident_base AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.av_ident_base
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi),
  w_av_ident_backup_1 AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.av_ident_backup_1
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi),
  w_av_ident_backup_2 AS (
    PARTITION BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.av_ident_backup_2
    ORDER BY
      base_ident.study_id,
      base_ident.item_group_id,
      base_ident.item_id,
      base_ident.item_multi_order_over_rsi)
ORDER BY
  base_ident.study_id,
  base_ident.item_group_id,
  base_ident.item_ordinal_per_ig_over_crfv,
  base_ident.item_multi_order_over_rsi NULLS FIRST;

