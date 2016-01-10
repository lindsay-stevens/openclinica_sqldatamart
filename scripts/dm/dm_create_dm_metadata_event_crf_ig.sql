CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata_event_crf_ig()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.metadata_event_crf_ig AS
        SELECT
            DISTINCT ON (study_name, event_oid, crf_version_oid, item_group_oid)
            study_name,
            study_status,
            study_date_created,
            study_date_updated,
            site_oid,
            site_name,
            event_oid,
            event_order,
            event_name,
            event_date_created,
            event_date_updated,
            event_repeating,
            crf_parent_oid,
            crf_parent_name,
            crf_parent_date_created,
            crf_parent_date_updated,
            crf_version,
            crf_version_oid,
            crf_version_date_created,
            crf_version_date_updated,
            crf_is_required,
            crf_is_double_entry,
            crf_is_hidden,
            crf_null_values,
            crf_section_label,
            crf_section_title,
            item_group_oid,
            item_group_name
        FROM
            dm.metadata;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;