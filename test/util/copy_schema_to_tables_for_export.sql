CREATE OR REPLACE FUNCTION public.copy_schema_to_tables_for_export(
  from_schema TEXT, 
  to_schema TEXT DEFAULT $$$$ :: text, 
  export_views_in_schema BOOLEAN DEFAULT TRUE)
RETURNS VOID AS $b$

/* 
Prepare a study schema for export to it's own database by copying the schema with matviews as tables.

Parameters.
- from_schema: name of the study schema to prepare.
- to_schema: name of the schema copy, where the tables are created.
- export_views_in_schema: if TRUE, copy over any views in the schema. 

Description.
This function makes a new schema and creates table copies of matviews in the original schema. The intention is to prepare a schema that could be exported on it's own with pg_dump, then restored into a new database with pg_restore.

By default, the schema will include any regular views; this process replaces the schema names in the query definition. If any views refer to objects in other schemas, these views will not work after doing a pg_restore to a separate database because the objects won't exist there.
*/

DECLARE 
  matview_record RECORD;
  view_record RECORD;
BEGIN

/* If to_schema not specified, default to the from_schema suffixed with "_t" */
IF (to_schema = $$$$) THEN
  to_schema := concat(from_schema, $s$_t$s$);
END IF;

/* Make a schema for the table-based copy. */
EXECUTE format($q$DROP SCHEMA IF EXISTS %1$I CASCADE;$q$, to_schema);
EXECUTE format($q$CREATE SCHEMA %1$I;$q$, to_schema);

/* Copy the materialized views into tables in the new schema. */
FOR matview_record IN 
  SELECT 
    schemaname, 
    matviewname 
  FROM pg_catalog.pg_matviews 
  WHERE schemaname = from_schema
LOOP
  EXECUTE format($q$
    CREATE TABLE %1$I.%3$I AS 
    SELECT * FROM %2$I.%3$I;$q$,
    to_schema,
    from_schema,
    matview_record.matviewname);
END LOOP;

/* Copy the view definitions over, replacing the schema name. */
/* In study schemas, these views apply column aliases for shorter names. */
IF (export_views_in_schema) THEN
  FOR view_record IN
    SELECT 
      format($q$CREATE OR REPLACE VIEW %1$I.%2$I AS %3$s;$q$,
        to_schema,
        viewname,
        replace(
          pg_get_viewdef(
            format($f$%1$I.%2$I$f$, schemaname, viewname), true),
          format($s$FROM %1$s.$s$, from_schema),
          format($s$FROM %1$s.$s$, to_schema)
        )
      ) AS create_view
    FROM pg_views
    WHERE schemaname = from_schema
  LOOP
    EXECUTE view_record.create_view;
  END LOOP;
END IF;

END$b$ LANGUAGE plpgsql VOLATILE;
