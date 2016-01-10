CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_itemgroup_matviews(
    alias_views          BOOLEAN DEFAULT FALSE,
    filter_study_name    TEXT DEFAULT $$$$ :: TEXT,
    filter_itemgroup_oid TEXT DEFAULT $$$$ :: TEXT)
    RETURNS TEXT AS
    $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN

WITH itemgroup_objects__crf_nulls AS ( 
/* List of all CRF null values */
SELECT 
  crf_nulls_distinct.study_name,
  crf_nulls_distinct.item_group_oid,
  btrim(
    array_to_string(
      array_agg(
        quote_literal(
          btrim(crf_nulls_distinct.crf_null_values, ',')
        )
      ), ','
    ), ','
  ) AS crf_null_values
  FROM (

SELECT DISTINCT 
  metadata.study_name,
  metadata.item_group_oid,
  metadata.crf_null_values
FROM dm.metadata_event_crf_ig AS metadata
WHERE metadata.crf_null_values <> ''

) AS crf_nulls_distinct
GROUP BY 
  crf_nulls_distinct.study_name, 
  crf_nulls_distinct.item_group_oid
),

itemgroup_objects__naming_decision AS (
/* If item_names are long, use item_oid instead of item name and description */
SELECT 
  meta.study_name,
  meta.item_group_oid,
  meta.item_oid,
  lower(meta.item_name) AS item_name,
  lower(
    CASE
      WHEN use_item_oid.use_item_oid 
      THEN substr(meta.item_oid, 1, 57)
      ELSE format(
        $fmt$%1$s_%2$s$fmt$,
        substr(dm_clean_name_string(meta.item_name), 1, 12), 
        substr(dm_clean_name_string(meta.item_description), 1, 45)
      )
    END
  ) AS item_name_hint,
  meta.item_data_type,
  meta.item_response_type,
  meta.item_response_order_multi,
  max(meta.item_response_set_label) as item_response_set_label
FROM dm.metadata_study AS dmms
INNER JOIN dm.metadata_crf_ig_item AS meta 
  ON meta.study_name = dmms.study_name
LEFT JOIN ( 

SELECT 
  metadata.study_name,
  bool_or(
    metadata.item_name ~ '^[0-9].+$' 
    OR length(metadata.item_name) > 12
  ) AS use_item_oid
FROM dm.metadata_crf_ig_item AS metadata
GROUP BY metadata.study_name

) AS use_item_oid 
  ON meta.study_name = use_item_oid.study_name

GROUP BY
  meta.study_name,
  meta.item_group_oid,
  meta.item_oid,
  meta.item_name,
  meta.item_description,
  meta.item_data_type,
  meta.item_response_type,
  meta.item_response_order_multi,
  use_item_oid.use_item_oid
ORDER BY
  meta.study_name,
  meta.item_group_oid,
  max(meta.item_form_order),
  max(meta.item_response_set_label),
  meta.item_response_order_multi NULLS FIRST
),

itemgroup_objects__item_fragments AS (
/* Generate SQL fragments for each item column value (and label) */
SELECT
  naming_decision.study_name,
  naming_decision.item_group_oid,
  array_to_string(
    array_agg(
      format(
        $fmt$ %1$s %2$s $fmt$,
        /* Create an expression for determining the item value. */
        /* - Replace one or more consecutive spaces with SQL null. */
        /* - Cast value to data type determined below. */
        format(
          $fmt$
          max(
            CASE 
              WHEN item_oid=%1$L
              THEN (
                CASE
                  WHEN item_value ~ $re$^[\s]*?$$re$
                  THEN NULL %2$s 
                  ELSE %3$s
                END
              ) 
              ELSE NULL
            END
          ) AS %4$I
          $fmt$,
          naming_decision.item_oid,
          /* Replace CRF null flavour values with SQL null. */
          /* If there are no CRF nulls set for the item group, don't bother. */
          CASE
            WHEN crf_nulls.crf_null_values IS NULL
            THEN NULL
            ELSE format(
              $fmt$
                WHEN item_value IN (%1$s) THEN NULL
              $fmt$,
              crf_nulls.crf_null_values
            )
          END,
          format(
            /* For multi-values, add function to pick by index from CSV. */
            $fmt$CAST(%1$s AS %2$s)$fmt$,
            CASE
              WHEN naming_decision.item_response_type IN ('multi-select', 'checkbox')
                AND naming_decision.item_response_order_multi IS NOT NULL
              THEN format(
                $arr$(string_to_array(item_value, ','))[%1$s]$arr$,
                naming_decision.item_response_order_multi
                )
              ELSE 'item_value'
            END,
            /* Determine the SQL data type to cast to. */
            /* - multi-value original CSV data: TEXT.  */
            /* - multi-value split data: data type specified in CRF. */
            /* - ST, PDATE or FILE: mappable only to TEXT. */
            /* - INT or REAL: NUMERIC to avoid needing to specify precision. */
            CASE
              WHEN naming_decision.item_response_type IN ('multi-select', 'checkbox')
                AND naming_decision.item_response_order_multi IS NULL
              THEN 'text'
              WHEN naming_decision.item_data_type IN ('ST', 'PDATE', 'FILE')
              THEN 'text'
              WHEN naming_decision.item_data_type IN ('INT', 'REAL')
              THEN 'numeric'
              ELSE naming_decision.item_data_type
            END
          ),
          naming_decision.item_name_hint
        ),
        CASE
          WHEN naming_decision.item_response_set_label IS NULL 
          THEN NULL
          ELSE format(
          /* As above, create an expression for determining the item label. */
            $fmt$
            ,max(
              CASE
                WHEN item_oid=%1$L
                THEN (
                  CASE
                    WHEN item_value ~ $re$^[\s]*?$$re$
                    THEN NULL %2$s
                    ELSE option_text 
                  END
                )
              ELSE NULL 
              END
            ) AS %3$s_label
            $fmt$, 
            naming_decision.item_oid,
            CASE
              WHEN crf_nulls.crf_null_values IS NULL
              THEN NULL
              ELSE format(
                $fmt$
                  WHEN item_value IN (%1$s) THEN NULL
                $fmt$,
                crf_nulls.crf_null_values
              )
            END,
            naming_decision.item_name_hint
          )
        END
      )
    ),
    ','
  ) AS item_ddl,
  array_to_string(
    array_agg(
      format(
        $fmt$ %1$s %2$s $fmt$, 
        format(
          $fmt$ %1$s AS %2$s $fmt$,
          naming_decision.item_name_hint,
          naming_decision.item_name
        ),
        CASE
          WHEN naming_decision.item_response_set_label IS NULL
          THEN NULL
          ELSE format(
            $fmt$ , %1$s_label AS %2$s_label $fmt$,
            naming_decision.item_name_hint,
            naming_decision.item_name
          )
        END
      )
    ),
    ','
  ) AS item_ddl_av
FROM itemgroup_objects__naming_decision AS naming_decision
LEFT JOIN itemgroup_objects__crf_nulls crf_nulls
  ON naming_decision.study_name = crf_nulls.study_name
  AND naming_decision.item_group_oid = crf_nulls.item_group_oid
GROUP BY 
  naming_decision.study_name,
  naming_decision.item_group_oid
),

itemgroup_objects__itemgroup_fragments AS (
/* Generate SQL fragments for each item group from / where / groupby clause */
SELECT DISTINCT ON (metadata_study.study_name, itemgroups.item_group_oid)
  metadata_study.study_name,
  itemgroups.item_group_oid,
  metadata_study.study_name_clean,
  format(
      $fmt$ FROM %1$I.clinicaldata WHERE item_group_oid=%2$L
        GROUP BY study_name, site_oid, site_name, subject_id, event_oid,
        event_name, event_order, event_repeat, crf_parent_name, crf_version,
        crf_version_oid, crf_status, item_group_oid, item_group_repeat;
      $fmt$,
    metadata_study.study_name_clean,
    itemgroups.item_group_oid
  ) AS ig_ddl,
  format(
    $fmt$ FROM %1$I.%2$I; $fmt$,
    metadata_study.study_name_clean,
    lower(itemgroups.item_group_oid)
  ) AS ig_ddl_av
FROM dm.metadata_study
INNER JOIN dm.metadata_event_crf_ig AS itemgroups 
  ON metadata_study.study_name = itemgroups.study_name
),

itemgroup_objects__sql AS (
/* Generate full SQL queries for item group matviews or alias views */
SELECT 
  format(
    $fmt$CREATE %1$s VIEW %2$I.%3$I AS 
    SELECT study_name, site_oid, site_name, subject_id, event_oid, event_name,
      event_order, event_repeat, crf_parent_name, crf_version, crf_version_oid,
      crf_status, item_group_oid, item_group_repeat, %4$s %5$s 
    $fmt$,
    (
      CASE
        WHEN alias_views
        THEN ''
        ELSE $$MATERIALIZED$$
      END
    ),
    itemgroup_fragments.study_name_clean,
    lower(
      CASE
        WHEN alias_views
        THEN concat($$av_$$, itemgroup_fragments.item_group_oid)
        ELSE itemgroup_fragments.item_group_oid
      END
    ),
    (
      CASE
        WHEN alias_views
        THEN item_fragments.item_ddl_av
        ELSE item_fragments.item_ddl
      END
    ),
    (
      CASE
        WHEN alias_views
        THEN itemgroup_fragments.ig_ddl_av
        ELSE itemgroup_fragments.ig_ddl
      END
    )
  ) AS create_statement
FROM itemgroup_objects__itemgroup_fragments AS itemgroup_fragments
LEFT JOIN itemgroup_objects__item_fragments AS item_fragments
  ON itemgroup_fragments.study_name = item_fragments.study_name
  AND itemgroup_fragments.item_group_oid = item_fragments.item_group_oid
WHERE
  EXISTS(
     SELECT n.nspname
     FROM pg_namespace AS n
     WHERE n.nspname = itemgroup_fragments.study_name_clean
  )
  AND NOT EXISTS(
    SELECT n.nspname AS schemaname
    FROM pg_class AS c
    LEFT JOIN pg_namespace AS n
      ON n.oid = c.relnamespace
    WHERE
      c.relkind = (
        CASE
          WHEN alias_views
          THEN $$v$$
          ELSE $$m$$
        END
      )
      AND itemgroup_fragments.study_name_clean = n.nspname
      AND c.relname = (
        CASE
          WHEN alias_views
          THEN format(
            $$av_%1$s$$,
            lower(itemgroup_fragments.item_group_oid)
          )
          ELSE lower(itemgroup_fragments.item_group_oid)
          END
        )
    ORDER BY c.oid
  )
  AND (
    CASE
      WHEN length(filter_study_name) > 0
      THEN itemgroup_fragments.study_name = filter_study_name
      ELSE TRUE
    END
  )
  AND (
    CASE
      WHEN length(filter_itemgroup_oid) > 0
      THEN itemgroup_fragments.item_group_oid = filter_itemgroup_oid
      ELSE TRUE
    END
  )
)

SELECT * FROM itemgroup_objects__sql

        LOOP
            EXECUTE r.create_statement;
        END LOOP;
        RETURN $$done$$;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;