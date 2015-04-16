CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_subject_groups()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.subject_groups AS
        SELECT
            sub.study_name,
            sub.site_name,
            sub.subject_id,
            gct.name       AS group_class_type,
            sgc.name       AS group_class_name,
            sgc.subject_assignment AS group_class_required,
            sg.name        AS group_name,
            sg.description AS group_description,
            sgm.notes      AS group_map_notes,
            sgm.date_created AS group_map_date_created,
            sgm.date_updated AS group_map_date_updated
        FROM
            dm.subjects AS sub
            INNER JOIN
            openclinica_fdw.subject_group_map AS sgm
                ON sgm.study_subject_id = sub.study_subject_id
            LEFT JOIN
            openclinica_fdw.study_group AS sg
                ON sg.study_group_id = sgm.study_group_id
            LEFT JOIN
            openclinica_fdw.study_group_class AS sgc
                ON sgc.study_group_class_id = sgm.study_group_class_id
            LEFT JOIN
            openclinica_fdw.group_class_types AS gct
                ON gct.group_class_type_id = sgc.group_class_type_id;
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;