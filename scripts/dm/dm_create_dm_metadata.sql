CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.metadata AS
    WITH study_with_status AS (
                    SELECT
                        study.parent_study_id,
                        study.study_id,
                        study.oc_oid,
                        study.name,
                        study.date_created,
                        study.date_updated,
                        study.status_id,
                        status_study.name AS status
                    FROM
                        openclinica_fdw.study
                    LEFT JOIN
                        status AS status_study
                        ON status_study.status_id = study.status_id
                ),
    metadata_no_multi AS (
            SELECT
                (
                    CASE
                    WHEN parents.name IS NOT NULL
                    THEN parents.name
                    ELSE study.name
                    END
                )                         AS study_name,
                (
                    CASE
                    WHEN parents.name IS NOT NULL
                    THEN parents.status
                    ELSE study.status
                    END
                )                         AS study_status,
                (
                    CASE
                    WHEN parents.name IS NOT NULL
                    THEN parents.date_created
                    ELSE study.date_created
                    END
                )                         AS study_date_created,
                (
                    CASE
                    WHEN parents.name IS NOT NULL
                    THEN parents.date_updated
                    ELSE study.date_updated
                    END
                )                         AS study_date_updated,
                study.oc_oid              AS site_oid,
                study.name                AS site_name,
                sed.oc_oid                AS event_oid,
                sed.ordinal               AS event_order,
                sed.name                  AS event_name,
                sed.date_created          as event_date_created,
                sed.date_updated          AS event_date_updated,
                sed.repeating             AS event_repeating,
                crf.oc_oid                AS crf_parent_oid,
                crf.name                  AS crf_parent_name,
                crf.date_created          AS crf_parent_date_created,
                crf.date_updated          AS crf_parent_date_updated,
                cv.name                   AS crf_version,
                cv.oc_oid                 AS crf_version_oid,
                cv.date_created           AS crf_version_date_created,
                cv.date_updated           AS crf_version_date_updated,
                edc.required_crf          AS crf_is_required,
                edc.double_entry          AS crf_is_double_entry,
                edc.hide_crf              AS crf_is_hidden,
                edc.null_values           AS crf_null_values,
                sct.label                 AS crf_section_label,
                sct.title                 AS crf_section_title,
                ig.oc_oid                 AS item_group_oid,
                ig.name                   AS item_group_name,
                ifm.ordinal               AS item_form_order,
                i.oc_oid                  AS item_oid,
                i.units                   AS item_units,
                id.code                  AS item_data_type,
                rt.name                   AS item_response_type,
                (
                    CASE
                    WHEN rs.label IN (
                        'text',
                        'textarea'
                    )
                    THEN NULL
                    ELSE rs.label
                    END
                )                         AS item_response_set_label,
                rs.response_set_id        AS item_response_set_id,
                rs.version_id             AS item_response_set_version,
                ifm.question_number_label AS item_question_number,
                i.name                    AS item_name,
                i.description             AS item_description,
                ifm.header                AS item_header,
                ifm.subheader             AS item_subheader,
                ifm.left_item_text        AS item_left_item_text,
                ifm.right_item_text       AS item_right_item_text,
                ifm.regexp                AS item_regexp,
                ifm.regexp_error_msg      AS item_regexp_error_msg,
                ifm.required              AS item_required,
                ifm.default_value         AS item_default_value,
                ifm.response_layout       AS item_response_layout,
                ifm.widh_decimal         AS item_widh_decimal,
                ifm.show_item             AS item_show_item,
                sim.item_oid              AS item_scd_item_oid,
                sim.option_value          AS item_scd_item_option_value,
                sim.option_text           AS item_scd_item_option_text,
                sim.message               AS item_scd_validation_message
            FROM
                study_with_status AS study
                INNER JOIN
                openclinica_fdw.study_event_definition AS sed
                    ON sed.study_id = study.study_id
                INNER JOIN
                openclinica_fdw.event_definition_crf AS edc
                    ON edc.study_event_definition_id =
                       sed.study_event_definition_id
                INNER JOIN
                openclinica_fdw.crf_version AS cv
                    ON cv.crf_id = edc.crf_id
                INNER JOIN
                openclinica_fdw.crf
                    ON crf.crf_id = cv.crf_id
                       AND crf.crf_id = edc.crf_id
                INNER JOIN
                openclinica_fdw.item_group AS ig
                    ON ig.crf_id = crf.crf_id
                INNER JOIN
                openclinica_fdw.item_group_metadata AS igm
                    ON igm.item_group_id = ig.item_group_id
                       AND igm.crf_version_id = cv.crf_version_id
                INNER JOIN
                openclinica_fdw.item_form_metadata AS ifm
                    ON cv.crf_version_id = ifm.crf_version_id
                INNER JOIN
                openclinica_fdw."section" AS sct
                    ON sct.crf_version_id = cv.crf_version_id
                       AND sct.section_id = ifm.section_id
                INNER JOIN
                openclinica_fdw.response_set AS rs
                    ON rs.response_set_id = ifm.response_set_id
                       AND rs.version_id = ifm.crf_version_id
                INNER JOIN
                openclinica_fdw.response_type AS rt
                    ON rs.response_type_id = rt.response_type_id
                INNER JOIN
                openclinica_fdw.item AS i
                    ON i.item_id = ifm.item_id
                       AND i.item_id = igm.item_id
                INNER JOIN
                openclinica_fdw.item_data_type AS id
                    ON id.item_data_type_id = i.item_data_type_id
                LEFT JOIN
                study_with_status AS parents
                    ON parents.study_id = study.parent_study_id
                LEFT JOIN
                (
                    SELECT
                        sim.scd_item_form_metadata_id,
                        sim.control_item_form_metadata_id,
                        sim.message,
                        i.oc_oid AS item_oid,
                        i.status_id,
                        sim.option_value,
                        response_sets.option_text
                    FROM
                        openclinica_fdw.scd_item_metadata AS sim
                        INNER JOIN
                        openclinica_fdw.item_form_metadata AS ifm
                            ON ifm.item_form_metadata_id =
                               sim.control_item_form_metadata_id
                        INNER JOIN
                        openclinica_fdw.item AS i
                            ON ifm.item_id = i.item_id
                        LEFT JOIN
                        dm.response_sets
                            ON ifm.response_set_id =
                               response_sets.response_set_id
                               AND ifm.crf_version_id = response_sets.version_id
                               AND
                               sim.option_value = response_sets.option_value) AS
                sim
                    ON ifm.item_form_metadata_id = sim.scd_item_form_metadata_id
            WHERE
                edc.parent_id IS NULL
                AND study.status_id NOT IN (5, 7) --removed, auto-removed
                AND sed.status_id NOT IN (5, 7)
                AND edc.status_id NOT IN (5, 7)
                AND cv.status_id NOT IN (5, 7)
                AND crf.status_id NOT IN (5, 7)
                AND ig.status_id NOT IN (5, 7)
                AND i.status_id NOT IN (5, 7)
                AND sct.status_id NOT IN (5, 7)
    )
SELECT
    metadata_no_multi.study_name,
    metadata_no_multi.study_status,
    metadata_no_multi.study_date_created,
    metadata_no_multi.study_date_updated,
    metadata_no_multi.site_oid,
    metadata_no_multi.site_name,
    metadata_no_multi.event_oid,
    metadata_no_multi.event_order,
    metadata_no_multi.event_name,
    metadata_no_multi.event_date_created,
    metadata_no_multi.event_date_updated,
    metadata_no_multi.event_repeating,
    metadata_no_multi.crf_parent_oid,
    metadata_no_multi.crf_parent_name,
    metadata_no_multi.crf_parent_date_created,
    metadata_no_multi.crf_parent_date_updated,
    metadata_no_multi.crf_version,
    metadata_no_multi.crf_version_oid,
    metadata_no_multi.crf_version_date_created,
    metadata_no_multi.crf_version_date_updated,
    metadata_no_multi.crf_is_required,
    metadata_no_multi.crf_is_double_entry,
    metadata_no_multi.crf_is_hidden,
    metadata_no_multi.crf_null_values,
    metadata_no_multi.crf_section_label,
    metadata_no_multi.crf_section_title,
    metadata_no_multi.item_group_oid,
    metadata_no_multi.item_group_name,
    metadata_no_multi.item_form_order,
    (
        CASE
        WHEN metadata_no_multi.item_response_type NOT IN
             (
                 'multi-select',
                 'checkbox'
             )
        THEN metadata_no_multi.item_oid
        WHEN metadata_no_multi.item_response_type IN
             (
                 'multi-select',
                 'checkbox'
             )
        THEN mv.item_oid
        ELSE 'unhandled'
        END
    ) AS item_oid,
    (
        CASE
        WHEN metadata_no_multi.item_response_type NOT IN
             (
                 'multi-select',
                 'checkbox'
             )
        THEN metadata_no_multi.item_name
        WHEN metadata_no_multi.item_response_type IN
             (
                 'multi-select',
                 'checkbox'
             )
        THEN mv.item_name
        ELSE 'unhandled'
        END
    ) AS item_name,
    mv.item_oid_multi_original,
    mv.item_name_multi_original,
    mv.item_response_order_multi,
    metadata_no_multi.item_units,
    metadata_no_multi.item_data_type,
    metadata_no_multi.item_response_type,
    metadata_no_multi.item_response_set_label,
    metadata_no_multi.item_response_set_id,
    metadata_no_multi.item_response_set_version,
    metadata_no_multi.item_question_number,
    metadata_no_multi.item_description,
    metadata_no_multi.item_header,
    metadata_no_multi.item_subheader,
    metadata_no_multi.item_left_item_text,
    metadata_no_multi.item_right_item_text,
    metadata_no_multi.item_regexp,
    metadata_no_multi.item_regexp_error_msg,
    metadata_no_multi.item_required,
    metadata_no_multi.item_default_value,
    metadata_no_multi.item_response_layout,
    metadata_no_multi.item_widh_decimal,
    metadata_no_multi.item_show_item,
    metadata_no_multi.item_scd_item_oid,
    metadata_no_multi.item_scd_item_option_value,
    metadata_no_multi.item_scd_item_option_text,
    metadata_no_multi.item_scd_validation_message
FROM
    metadata_no_multi
    LEFT JOIN
    (
        SELECT
            mnm.item_oid  AS item_oid_multi_original,
            mnm.item_name AS item_name_multi_original,
            response_sets.option_order AS item_response_order_multi,
            format(
                    $$%1$s_%2$s$$,
                    mnm.item_oid,
                    response_sets.option_order
            )             AS item_oid,
            format(
                    $$%1$s_%2$s$$,
                    mnm.item_name,
                    response_sets.option_order
            )             AS item_name
        FROM
            dm.response_sets
            LEFT JOIN
            (
                SELECT
                    DISTINCT ON (metadata_no_multi.item_oid)
                    metadata_no_multi.item_oid,
                    metadata_no_multi.item_name,
                    max(metadata_no_multi.item_response_set_id) AS item_response_set_id,
                    max(metadata_no_multi.item_response_set_version) AS item_response_set_version
                FROM
                    metadata_no_multi
                WHERE
                    metadata_no_multi.item_response_type
                    IN (
                        'multi-select',
                        'checkbox'
                    )
                GROUP BY
                    metadata_no_multi.item_oid,
                    metadata_no_multi.item_name
            ) AS mnm
                ON mnm.item_response_set_id =
                   response_sets.response_set_id
                   AND mnm.item_response_set_version =
                       response_sets.version_id
        UNION ALL
        SELECT
            DISTINCT ON (metadata_no_multi.item_oid)
            metadata_no_multi.item_oid  AS item_oid_multi_original,
            metadata_no_multi.item_name AS item_name_multi_original,
            NULL AS item_response_order_multi,
            metadata_no_multi.item_oid,
            metadata_no_multi.item_name
        FROM
            metadata_no_multi
        WHERE
            metadata_no_multi.item_response_type IN
            (
                'multi-select',
                'checkbox'
            )
    ) AS mv
        ON mv.item_oid_multi_original = metadata_no_multi.item_oid
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;