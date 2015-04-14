CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata_crf_ig_item()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.metadata_crf_ig_item AS
        SELECT
            DISTINCT ON (study_name, crf_version_oid, item_oid)
            study_name,
            study_status,
            study_date_created,
            study_date_updated,
            site_oid,
            site_name,
            crf_parent_oid,
            crf_parent_name,
            crf_parent_date_created,
            crf_parent_date_updated,
            crf_version,
            crf_version_oid,
            crf_version_date_created,
            crf_version_date_updated,
            crf_section_label,
            crf_section_title,
            item_group_oid,
            item_group_name,
            item_form_order,
            item_oid,
            item_name,
            item_oid_multi_original,
            item_name_multi_original,
            item_units,
            item_data_type,
            item_response_type,
            item_response_set_label,
            item_response_set_id,
            item_response_set_version,
            item_question_number,
            item_description,
            item_header,
            item_subheader,
            item_left_item_text,
            item_right_item_text,
            item_regexp,
            item_regexp_error_msg,
            item_required,
            item_default_value,
            item_response_layout,
            item_width_decimal,
            item_show_item,
            item_scd_item_oid,
            item_scd_item_option_value,
            item_scd_item_option_text,
            item_scd_validation_message
        FROM
            dm.metadata;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;