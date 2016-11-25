CREATE OR REPLACE FUNCTION openclinica_fdw.dm_users_removed_role_oc_user_revoke_from_role()
  RETURNS TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        FOR r IN
        WITH all_users AS (
            SELECT
                initcap(
                        substring(
                                email
                                FROM
                                $$^([A-z]+)@$$
                        )
                ) AS email_local,
                role_name_ui,
                role_status,
                user_name,
                concat(
                        $$dm_study_$$,
                        openclinica_fdw.dm_clean_name_string(
                                study_name)
                )     AS study_name_role
            FROM
                dm.user_account_roles
            WHERE
                study_name IN (SELECT study_name FROM dm.metadata_study)
        )
        SELECT
            format(
                    $$ REVOKE %1$s FROM %2$I; $$,
                    study_name_role,
                    email_local
            ) AS statements,
            email_local
        FROM
            (
                SELECT
                    *
                FROM
                    all_users
                WHERE
                    role_name_ui LIKE $$study%$$
                    AND role_status = $$removed$$
                    AND email_local IN (
                        SELECT
                            pg_roles.rolname
                        FROM
                            pg_catalog.pg_roles
                        WHERE
                            pg_has_role(
                                    rolname,
                                    study_name_role,
                                    $$member$$
                            )
                    )
                    AND length(
                                email_local) > 0
                    AND user_name != $$root$$
            ) AS users_statements
        LOOP
            EXECUTE r.statements;
        END LOOP;
        RETURN $$done$$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;