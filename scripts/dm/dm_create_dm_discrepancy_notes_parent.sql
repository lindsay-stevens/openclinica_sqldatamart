CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_discrepancy_notes_parent()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.discrepancy_notes_parent AS
        SELECT
            sub.discrepancy_note_id,
            sub.study_name,
            sub.site_name,
            sub.subject_id,
            sub.event_name,
            sub.crf_parent_name,
            sub.crf_section_label,
            sub.item_description,
            sub.column_name,
            sub.parent_dn_id,
            sub.entity_type,
            sub.description,
            sub.detailed_notes,
            sub.date_created,
            sub.discrepancy_note_type,
            sub.resolution_status,
            sub.discrepancy_note_owner,
            CASE WHEN sub.resolution_status IN ($$Closed$$, $$Not Applicable$$)
            THEN NULL
            WHEN sub.resolution_status IN
                 ($$New$$, $$Updated$$, $$Resolution Proposed$$)
            THEN CURRENT_DATE - sub.date_created
            ELSE NULL
            END AS days_open,
            CASE WHEN sub.resolution_status IN ($$Closed$$, $$Not Applicable$$)
            THEN NULL
            WHEN sub.resolution_status IN
                 ($$New$$, $$Updated$$, $$Resolution Proposed$$)
            THEN CURRENT_DATE - (
                SELECT
                    max(
                            all_dates.date_created
                    )
                FROM
                    (SELECT
                         date_created
                     FROM
                         openclinica_fdw.discrepancy_note AS dn
                     WHERE
                         dn.parent_dn_id = sub.discrepancy_note_id
                     UNION ALL
                     SELECT
                         date_created
                     FROM
                         openclinica_fdw.discrepancy_note AS dn
                     WHERE
                         dn.parent_dn_id = sub.parent_dn_id
                     UNION ALL
                     SELECT
                         date_created
                     FROM
                         openclinica_fdw.discrepancy_note AS dn
                     WHERE
                         dn.discrepancy_note_id =
                         sub.discrepancy_note_id
                    ) AS all_dates
            )
            ELSE NULL
            END AS days_since_update
        FROM
            dm.discrepancy_notes_all AS sub
        WHERE
            sub.parent_dn_id IS NULL
        GROUP BY
            sub.discrepancy_note_id,
            sub.study_name,
            sub.site_name,
            sub.subject_id,
            sub.event_name,
            sub.crf_parent_name,
            sub.crf_section_label,
            sub.item_description,
            sub.column_name,
            sub.parent_dn_id,
            sub.entity_type,
            sub.description,
            sub.detailed_notes,
            sub.date_created,
            sub.discrepancy_note_type,
            sub.resolution_status,
            sub.discrepancy_note_owner;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;