CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_study_role(
  filter_study_name TEXT DEFAULT $$$$
)
  RETURNS TEXT AS
  $BODY$
    DECLARE
        r              RECORD;
        study_username VARCHAR;
        study_name     VARCHAR;
    BEGIN
        FOR r IN
        SELECT
            DISTINCT ON (metadata.study_name)
            dm_clean_name_string(
                    metadata.study_name
            ) AS study_name
        FROM
            dm.metadata
        WHERE
            metadata.study_name ~ (
                CASE
                WHEN length(
                             filter_study_name
                     ) > 0
                THEN filter_study_name
                ELSE $$.+$$
                END
            )
        LOOP
            study_name = r.study_name;
            study_username = format(
                    $$dm_study_%1$s$$,
                    r.study_name
            );
            IF NOT EXISTS(
                    SELECT
                        *
                    FROM
                        pg_catalog.pg_roles
                    WHERE
                        pg_roles.rolname = study_username
            ) THEN
                EXECUTE format(
                        $$CREATE ROLE %1$I NOLOGIN;$$,
                        study_username
                );
            END IF;
        END LOOP;
        RETURN $$done$$;
    END;
    $BODY$ LANGUAGE plpgsql VOLATILE;