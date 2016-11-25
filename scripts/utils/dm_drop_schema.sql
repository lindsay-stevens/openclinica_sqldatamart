CREATE OR REPLACE FUNCTION openclinica_fdw.dm_drop_schema(
  schema_name TEXT DEFAULT $$$$
)
  RETURNS VOID AS
  $BODY$
    BEGIN
        EXECUTE format($$DROP SCHEMA IF EXISTS %1$I CASCADE $$, openclinica_fdw.dm_clean_name_string(schema_name));
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;