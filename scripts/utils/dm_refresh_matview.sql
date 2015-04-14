CREATE OR REPLACE FUNCTION openclinica_fdw.dm_refresh_matview(
  schemaname  TEXT,
  matviewname TEXT
)
  RETURNS TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        FOR r IN
        SELECT
            format(
                    $$ REFRESH MATERIALIZED VIEW %1$I.%2$I ; $$,
                    schemaname,
                    matviewname
            ) AS refresh_statement
        LOOP
            EXECUTE r.refresh_statement;
        END LOOP;
        RETURN $$done$$;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;