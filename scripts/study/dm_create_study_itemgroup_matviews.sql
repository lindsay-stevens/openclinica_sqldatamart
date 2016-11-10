CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_itemgroup_matviews(
  alias_views BOOLEAN DEFAULT FALSE,
  filter_study_name TEXT DEFAULT $$$$ :: TEXT,
  filter_itemgroup_oid TEXT DEFAULT $$$$ :: TEXT)
RETURNS TEXT AS $b$
DECLARE
  r RECORD;
BEGIN

FOR r IN
  WITH use_item_oid AS (
    SELECT
      study_name,
      (
        max(length(metadata.item_name)) > 12
        OR max(
          CASE
            WHEN metadata.item_name ~ $reg$^[0-9].+$$reg$
              THEN length(metadata.item_name)
          END) > 0
      ) AS use_item_oid
    FROM dm.metadata_crf_ig_item AS metadata
    GROUP BY
      study_name
    ),

  crf_nulls AS (
    SELECT
      trim(BOTH ',' FROM
        (array_to_string(array_agg(quote_literal(
          trim(BOTH ',' FROM
            (sub.crf_null_values)))), $$,$$))
      ) AS crf_null_values,
      study_name,
      item_group_oid
      FROM (
        SELECT DISTINCT ON (study_name, event_oid, crf_version_oid)
          metadata.study_name,
          metadata.item_group_oid,
          metadata.crf_null_values
        FROM dm.metadata_event_crf_ig AS metadata
        WHERE metadata.crf_null_values != $$$$
      ) AS sub
      GROUP BY
        study_name,
        item_group_oid
  )

  SELECT
    format(
      $f$CREATE %1$s VIEW %2$I.%3$I AS SELECT study_name, site_oid, site_name,
        subject_id, event_oid, event_name, event_order, event_repeat,
        crf_parent_name, crf_version, crf_status, item_group_oid,
        item_group_repeat, %4$s %5$s $f$,
      CASE
        WHEN alias_views
          THEN $$$$
        ELSE $$MATERIALIZED$$
      END,
      dm_clean_name_string(ddl.study_name),
      CASE
        WHEN alias_views
          THEN concat($$av_$$, ddl.item_group_oid)
        ELSE ddl.item_group_oid
      END,
      array_to_string(
        array_agg(
          CASE
            WHEN alias_views
              THEN ddl.item_ddl_av
            ELSE ddl.item_ddl
          END),
        $$,$$),
      CASE
        WHEN alias_views
          THEN ddl.ig_ddl_av
        ELSE ddl.ig_ddl
      END
    ) AS create_statement
  FROM (
    SELECT
      format(
        $f$ %1$s %2$s $f$,
        format(
          $f$ max(
            CASE
              WHEN item_oid=%1$L then (
                CASE
                  WHEN item_value ~ '^[\s]*?$'
                    THEN NULL
                  WHEN item_value IN (%2$s)
                    THEN NULL
                  ELSE cast(item_value as %3$s)
                END)
              ELSE NULL
            END) as %4$I $f$,
          met.item_oid,
          CASE
            WHEN met.crf_null_values IS NULL
              THEN $$''$$
            ELSE met.crf_null_values
          END,
          CASE
            WHEN item_data_type IN ($$ST$$, $$PDATE$$, $$FILE$$)
              THEN $$text$$
            WHEN item_data_type IN ($$INT$$, $$REAL$$)
              THEN $$numeric$$
            ELSE item_data_type
          END,
          met.item_name_hint
        ),
        CASE
          WHEN met.item_response_set_label IS NULL
            THEN NULL
          ELSE format(
            $f$ , max(
              CASE
                WHEN item_oid=%1$L
                  THEN (
                    CASE
                      WHEN item_value ~ $s$^[\s]*?$$s$
                        THEN NULL
                      WHEN item_value IN (%2$s)
                        THEN NULL
                      ELSE option_text
                    END)
                ELSE NULL
              END) as %3$s_label $f$,
            met.item_oid,
            CASE
              WHEN met.crf_null_values IS NULL
                THEN $$''$$
              ELSE met.crf_null_values
            END,
            met.item_name_hint)
        END
      ) AS item_ddl,
      format(
        $f$
          FROM %1$I.clinicaldata
          WHERE item_group_oid=%2$L
          GROUP BY
            study_name, site_oid, site_name, subject_id, event_oid,
            event_name, event_order, event_repeat, crf_parent_name,
            crf_version, crf_status, item_group_oid, item_group_repeat;
        $f$,
        dm_clean_name_string(met.study_name),
        upper(met.item_group_oid)
      ) AS ig_ddl,
      item_group_oid,
      study_name,
      format(
        $f$ %1$s %2$s $f$,
        format(
          $f$ %1$s AS %2$s $f$,
          met.item_name_hint,
          met.item_name
        ),
        CASE
          WHEN met.item_response_set_label IS NULL
            THEN NULL
          ELSE format(
            $f$ , %1$s_label AS %2$s_label $f$,
            met.item_name_hint,
            met.item_name)
        END
      ) AS item_ddl_av,
      format(
        $f$ FROM %1$I.%2$I;$f$,
        dm_clean_name_string(met.study_name),
        met.item_group_oid
      ) AS ig_ddl_av,
      item_form_order
    FROM (
      SELECT
        study_name,
        lower(item_group_oid) AS item_group_oid,
        item_oid,
        lower(item_name) AS item_name,
        lower(
          CASE
            WHEN length(item_name_hint) > 57
              THEN substr(item_name_hint, 1, 57)
            ELSE item_name_hint
          END) AS item_name_hint,
        item_data_type,
        max(item_form_order) AS item_form_order,
        max(item_response_set_label) AS item_response_set_label,
        crf_null_values
      FROM (
        SELECT
          dm_meta.study_name,
          dm_meta.item_group_oid,
          item_oid,
          item_name,
          CASE
            WHEN use_item_oid.use_item_oid
              THEN item_oid
            ELSE lower(
              format(
                $$%1$s_%2$s$$,
                substr(dm_clean_name_string(dm_meta.item_name), 1, 12),
                substr(dm_clean_name_string(dm_meta.item_description), 1, 45)
              )
            )
          END AS item_name_hint,
          item_data_type,
          item_form_order,
          item_response_set_label,
          crf_nulls.crf_null_values
        FROM dm.metadata_crf_ig_item AS dm_meta
        LEFT JOIN use_item_oid
          ON use_item_oid.study_name = dm_meta.study_name
        LEFT JOIN crf_nulls
          ON crf_nulls.study_name = dm_meta.study_name
          AND crf_nulls.item_group_oid = dm_meta.item_group_oid
        INNER JOIN dm.metadata_study AS dmms
          ON dmms.study_name = dm_meta.study_name
        WHERE
          EXISTS(
            SELECT n.nspname
            FROM pg_namespace AS n
            WHERE n.nspname = dmms.study_name_clean
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
                END)
              AND dmms.study_name_clean = n.nspname
              AND c.relname = (
                CASE
                  WHEN alias_views
                    THEN format($$av_%1$s$$, lower(dm_meta.item_group_oid))
                  ELSE lower(dm_meta.item_group_oid)
                END)
            ORDER BY c.oid
          )
          AND (
            CASE
              WHEN length(filter_study_name) > 0
                THEN dm_meta.study_name = filter_study_name
              ELSE TRUE
            END)
          AND (
            CASE
              WHEN length(filter_itemgroup_oid) > 0
                THEN dm_meta.item_group_oid = filter_itemgroup_oid
              ELSE TRUE
            END)
      ) AS namecheck
      GROUP BY
        study_name,
        item_group_oid,
        item_oid,
        item_name,
        item_name_hint,
        item_data_type,
        crf_null_values
      ORDER BY
        study_name,
        item_group_oid,
        item_form_order,
        item_name
    ) AS met
  ) AS ddl
  GROUP BY
    ddl.study_name,
    ddl.item_group_oid,
    ddl.ig_ddl,
    ddl.ig_ddl_av

LOOP
  EXECUTE r.create_statement;
END LOOP;

RETURN $$done$$;

END$b$ LANGUAGE plpgsql VOLATILE;