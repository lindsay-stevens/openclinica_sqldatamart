CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_response_set_labels()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.response_set_labels AS
        SELECT
            DISTINCT
            md.study_name,
            md.crf_parent_name,
            md.crf_version,
            md.crf_version_oid,
            md.item_group_oid,
            md.item_group_name,
            md.item_form_order,
            md.item_oid,
            md.item_name,
            md.item_description,
            rs.version_id,
            rs.label,
            rs.option_value,
            rs.option_text,
            rs.option_order
        FROM
            dm.metadata AS md
            INNER JOIN
            dm.response_sets AS rs
                ON rs.version_id = md.item_response_set_version
                   AND rs.label = md.item_response_set_label
        ORDER BY
            md.study_name,
            md.crf_parent_name,
            md.crf_version,
            md.item_group_oid,
            md.item_form_order,
            rs.version_id,
            rs.label,
            rs.option_value;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;