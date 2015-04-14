CREATE OR REPLACE FUNCTION openclinica_fdw.dm_users_removed_oc_user_alter_role_nologin()
  RETURNS TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        FOR r IN
        SELECT
            DISTINCT ON (email_local)
            format(
                    $$ ALTER ROLE %1$I NOLOGIN; $$,
                    email_local
            ) AS statements,
            email_local
        FROM
            (
                SELECT
                    *
                FROM
                    (
                        SELECT
                            initcap(
                                    substring(
                                            email
                                            FROM
                                            $$^([A-z]+)@$$
                                    )
                            ) AS email_local,
                            role_name_ui,
                            account_status,
                            user_name
                        FROM
                            dm.user_account_roles
                    ) AS all_users
                WHERE
                    role_name_ui LIKE $$study%$$
                    AND account_status = $$removed$$
                    AND email_local IN (
                        SELECT
                            pg_roles.rolname
                        FROM
                            pg_catalog.pg_roles
                    )
                    AND length(
                                email_local
                        ) > 0
                    AND user_name != $$root$$
            ) AS users_statements
        LOOP
            EXECUTE r.statements;
        END LOOP;
        RETURN $$done$$;
    END;
    $BODY$
LANGUAGE plpgsql VOLATILE;