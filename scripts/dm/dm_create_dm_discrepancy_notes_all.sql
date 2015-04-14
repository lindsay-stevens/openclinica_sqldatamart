CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_discrepancy_notes_all()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.discrepancy_notes_all AS
        SELECT
            dn_src.discrepancy_note_id,
            dn_src.study_name,
            dn_src.site_name,
            dn_src.subject_id,
            dn_src.event_name,
            dn_src.crf_parent_name,
            dn_src.crf_section_label,
            dn_src.item_description,
            dn_src.column_name,
            dn_src.parent_dn_id,
            dn_src.entity_type,
            dn_src.description,
            dn_src.detailed_notes,
            dn_src.date_created,
            dn_src.discrepancy_note_type,
            dn_src.resolution_status,
            dn_src.discrepancy_note_owner
        FROM
            (
                SELECT
                    DISTINCT ON (sua.discrepancy_note_id)
                    sua.discrepancy_note_id,
                    sua.study_name,
                    sua.site_name,
                    sua.subject_id,
                    sua.event_name,
                    sua.crf_parent_name,
                    sua.crf_section_label,
                    sua.item_description,
                    sua.column_name,
                    dn.parent_dn_id,
                    dn.entity_type,
                    dn.description,
                    dn.detailed_notes,
                    dn.date_created,
                    CASE
                    WHEN dn.discrepancy_note_type_id =
                         1 THEN $$Failed Validation Check$$ :: TEXT
                    WHEN dn.discrepancy_note_type_id =
                         2 THEN $$Annotation$$ :: TEXT
                    WHEN dn.discrepancy_note_type_id = 3 THEN $$Query$$ :: TEXT
                    WHEN dn.discrepancy_note_type_id =
                         4 THEN $$Reason for Change$$ :: TEXT
                    ELSE $$unhandled$$ :: TEXT
                    END :: TEXT                  AS discrepancy_note_type,
                    rs.name                      AS resolution_status,
                    ua.user_name                 AS discrepancy_note_owner
                FROM
                    (
                        (
                            (
                                (
                                    SELECT
                                        didm.discrepancy_note_id,
                                        didm.column_name,
                                        cd.study_name,
                                        cd.site_name,
                                        cd.subject_id,
                                        cd.event_name,
                                        cd.crf_parent_name,
                                        cd.crf_section_label,
                                        cd.item_description
                                    FROM
                                        openclinica_fdw.dn_item_data_map AS didm
                                        JOIN
                                        dm.clinicaldata AS cd
                                            ON cd.item_data_id =
                                               didm.item_data_id
                                    UNION ALL
                                    SELECT
                                        decm.discrepancy_note_id,
                                        decm.column_name,
                                        cd.study_name,
                                        cd.site_name,
                                        cd.subject_id,
                                        cd.event_name,
                                        cd.crf_parent_name,
                                        NULL :: TEXT AS crf_section_label,
                                        NULL :: TEXT AS item_description
                                    FROM
                                        openclinica_fdw.dn_event_crf_map AS decm
                                        JOIN
                                        dm.clinicaldata AS cd
                                            ON cd.event_crf_id =
                                               decm.event_crf_id
                                )
                                UNION ALL
                                SELECT
                                    dsem.discrepancy_note_id,
                                    dsem.column_name,
                                    cd.study_name,
                                    cd.site_name,
                                    cd.subject_id,
                                    cd.event_name,
                                    NULL :: TEXT AS crf_parent_name,
                                    NULL :: TEXT AS crf_section_label,
                                    NULL :: TEXT AS item_description
                                FROM
                                    openclinica_fdw.dn_study_event_map AS dsem
                                    JOIN
                                    dm.clinicaldata AS cd
                                        ON cd.study_event_id =
                                           dsem.study_event_id
                            )
                            UNION ALL
                            SELECT
                                dssm.discrepancy_note_id,
                                dssm.column_name,
                                cd.study_name,
                                cd.site_name,
                                cd.subject_id,
                                NULL :: TEXT AS event_name,
                                NULL :: TEXT AS crf_parent_name,
                                NULL :: TEXT AS crf_section_label,
                                NULL :: TEXT AS item_description
                            FROM
                                openclinica_fdw.dn_study_subject_map AS dssm
                                JOIN
                                dm.clinicaldata AS cd
                                    ON cd.study_subject_id =
                                       dssm.study_subject_id
                        )
                        UNION ALL
                        SELECT
                            dsm.discrepancy_note_id,
                            dsm.column_name,
                            cd.study_name,
                            cd.site_name,
                            cd.subject_id,
                            NULL :: TEXT AS event_name,
                            NULL :: TEXT AS crf_parent_name,
                            NULL :: TEXT AS crf_section_label,
                            NULL :: TEXT AS item_description
                        FROM
                            openclinica_fdw.dn_subject_map AS dsm
                            JOIN
                            dm.clinicaldata AS cd
                                ON cd.subject_id_seq = dsm.subject_id
                    ) AS sua
                    JOIN
                    openclinica_fdw.discrepancy_note AS dn
                        ON dn.discrepancy_note_id = sua.discrepancy_note_id
                    JOIN
                    openclinica_fdw.resolution_status AS rs
                        ON rs.resolution_status_id = dn.resolution_status_id
                    JOIN
                    openclinica_fdw.user_account AS ua
                        ON ua.user_id = dn.owner_id
            ) AS dn_src;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;