CREATE OR REPLACE FUNCTION openclinica_fdw.dm_grant_study_schema_access_to_study_role(
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
            EXECUTE format(
                    $$GRANT USAGE ON SCHEMA %1$I TO %2$I;$$,
                    study_name,
                    study_username
            );
            EXECUTE format(
                    $$GRANT SELECT ON ALL TABLES IN SCHEMA %1$I TO %2$I;$$,
                    study_name,
                    study_username
            );
            EXECUTE format(
                    $$ALTER DEFAULT PRIVILEGES IN SCHEMA %1$I GRANT SELECT ON TABLES TO %2$I;$$,
                    study_name,
                    study_username
            );
            EXECUTE format(
                    $$GRANT %1$I TO dm_admin;$$,
                    study_username
            );
        END LOOP;
        RETURN $$done$$;
    END;
    $BODY$ LANGUAGE plpgsql VOLATILE;