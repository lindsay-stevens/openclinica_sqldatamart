CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_user_account_roles()
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE $query$
    CREATE MATERIALIZED VIEW dm.user_account_roles AS
        SELECT
            ua.user_id,
            ua.user_name,
            ua.first_name,
            ua.last_name,
            ua.email,
            ua.date_created              AS account_created,
            ua.date_updated              AS account_last_updated,
            ua_status.name               AS account_status,
            COALESCE(
                    parents.unique_identifier,
                    study.unique_identifier,
                    $$no parent study$$) AS role_study_code,
            COALESCE(
                    parents.name,
                    study.name,
                    $$no parent study$$) AS study_name,
            CASE
            WHEN parents.unique_identifier IS NOT NULL
            THEN study.unique_identifier
            END                          AS role_site_code,
            CASE
            WHEN parents.name IS NOT NULL
            THEN study.name
            END                          AS role_site_name,
            CASE
            WHEN
                parents.name IS NULL
            THEN
                CASE
                WHEN role_name = $$admin$$
                THEN $$administrator$$
                WHEN role_name = $$coordinator$$
                THEN $$study data manager$$
                WHEN role_name = $$monitor$$
                THEN $$study monitor$$
                WHEN role_name = $$ra$$
                THEN $$study data entry person$$
                ELSE role_name
                END
            WHEN
                parents.name IS NOT NULL
            THEN
                CASE
                WHEN role_name = $$ra$$
                THEN $$clinical research coordinator$$
                WHEN role_name = $$monitor$$
                THEN $$site monitor$$
                WHEN role_name = $$Data Specialist$$
                THEN $$site investigator$$
                ELSE role_name
                END
            END                          AS role_name_ui,
            sur.date_created             AS role_created,
            sur.date_updated             AS role_last_updated,
            sur_status.name              AS role_status
        FROM
            openclinica_fdw.user_account AS ua
            LEFT JOIN
            openclinica_fdw.study_user_role AS sur
                ON ua.user_name = sur.user_name
            LEFT JOIN
            openclinica_fdw.study
                ON study.study_id = sur.study_id
            LEFT JOIN
            openclinica_fdw.study AS parents
                ON parents.study_id = study.parent_study_id
            LEFT JOIN
            openclinica_fdw.status AS ua_status
                ON ua.status_id = ua_status.status_id
            LEFT JOIN
            openclinica_fdw.status AS sur_status
                ON sur.status_id = sur_status.status_id
            $query$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;