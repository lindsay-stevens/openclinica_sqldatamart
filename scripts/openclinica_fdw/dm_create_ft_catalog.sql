CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_ft_catalog()
  RETURNS VOID AS
  $BODY$
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN
        WITH table_list AS (
                SELECT
                    table_list.table_name,
                    table_list.table_def
                FROM
                    (
                        VALUES
                            (
                                $$pg_attribute$$,
                                $$attrelid oid,
                                  attname name,
                                  atttypid oid,
                                  attstattarget integer,
                                  attlen smallint,
                                  attnum smallint,
                                  attndims integer,
                                  attcacheoff integer,
                                  atttypmod integer,
                                  attbyval boolean,
                                  attstorage "char",
                                  attalign "char",
                                  attnotnull boolean,
                                  atthasdef boolean,
                                  attisdropped boolean,
                                  attislocal boolean,
                                  attinhcount integer,
                                  attcollation oid,
                                  attacl aclitem[],
                                  attoptions text[],
                                  attfdwoptions text[]$$
                            ),
                            (
                                $$pg_class$$,
                                $$"oid" oid,
                                  relname name,
                                  relnamespace oid,
                                  reltype oid,
                                  reloftype oid,
                                  relowner oid,
                                  relam oid,
                                  relfilenode oid,
                                  reltablespace oid,
                                  relpages integer,
                                  reltuples real,
                                  relallvisible integer,
                                  reltoastrelid oid,
                                  relhasindex boolean,
                                  relisshared boolean,
                                  relpersistence "char",
                                  relkind "char"$$
                            ),
                            (
                                $$pg_namespace$$,
                                $$"oid" oid,
                                  nspname name$$
                            ),
                            (
                                $$pg_indexes$$,
                                $$schemaname name,
                                  tablename name,
                                  indexname name,
                                  indexdef text$$)
                    ) AS table_list (table_name, table_def)
        )
        SELECT
            format(
                    $$ CREATE FOREIGN TABLE openclinica_fdw.ft_%1$s (%2$s)
                       SERVER openclinica_fdw_server OPTIONS ( schema_name
                       'pg_catalog', table_name %1$L, updatable 'false' ); $$,
                    table_list.table_name,
                    table_list.table_def
            ) AS create_statements
        FROM
            table_list
        LOOP
            EXECUTE r.create_statements;
        END LOOP;
    END
    $BODY$
LANGUAGE plpgsql VOLATILE;