CREATE OR REPLACE FUNCTION public.dm_snapshot_code_stata(
  filter_study_name_schema     TEXT,
  outputdir                    TEXT,
  odbc_string_or_file_dsn_path TEXT,
  data_filter_string           TEXT DEFAULT $$$$
)
  RETURNS SETOF TEXT AS
  $BODY$
    DECLARE r RECORD;
    BEGIN
        RETURN QUERY
        WITH views AS (
                SELECT
                    pgc.relname,
                    pgc.relkind,
                    substring(pgc.relname FROM 4) as relname_substr
                FROM
                    pg_catalog.pg_class AS pgc
                    INNER JOIN
                    pg_catalog.pg_namespace AS pgn
                        ON pgc.relnamespace = pgn.oid
                WHERE
                    pgn.nspname = filter_study_name_schema
        ), header_rows AS (
            SELECT
                format(
                    $head$local snapshotdir="%1$s"$head$,
                    outputdir
                ) AS statements
            UNION ALL
            SELECT
                format(
                    $head$local data_filter_string="%1$s"$head$,
                    data_filter_string
                ) AS statements
            UNION ALL
            SELECT
                format(
                    $head$local odbc_string_or_file_dsn_path="%1$s"$head$,
                    odbc_string_or_file_dsn_path
                ) AS statements
        ), dm_metadata_study AS (
            SELECT
                study_name
            FROM dm.metadata_study
            WHERE study_name_clean = filter_study_name_schema
        ), label_cmds AS (
        
            /* LABEL VARIABLE - USING ITEM DESCRIPTION */
            SELECT DISTINCT ON (item_oid)
            format(
                $line$lab var %1$s "%2$s"$line$,
                lower(item_name),
                item_description    
            ) AS cmd,
            lower(item_group_oid) AS relname,
            21 AS suborder
            FROM dm.metadata_crf_ig_item
            INNER JOIN dm_metadata_study AS dms
                ON metadata_crf_ig_item.study_name = dms.study_name
            
            /* LABEL DEFINE - BUILD VALUE LABEL DEFINITIONS */
            UNION ALL
            SELECT DISTINCT ON (item_oid, option_order)
            format(
                $line$lab def %1$s_lbl %2$s "%3$s", modify$line$,
                lower(item_name),
                option_value,
                option_text
            ) AS cmd,
            lower(item_group_oid) AS relname,
            22 AS suborder
            FROM dm.response_set_labels AS drsl
            INNER JOIN dm_metadata_study AS dms
                ON drsl.study_name = dms.study_name
            WHERE 
                EXISTS (
                    SELECT
                        item_oid
                    FROM dm.metadata_crf_ig_item AS mcii
                    WHERE
                        drsl.item_oid = mcii.item_oid
                        AND mcii.item_data_type = 'INT'
                )
            
            /* LABEL VALUES - ONLY INTEGERS ARE VALID */
            UNION ALL
            SELECT DISTINCT ON (item_oid)
            format(
                $line$lab val %1$s %1$s_lbl$line$,
                lower(item_name)
            ) AS cmd,
            lower(item_group_oid) AS relname,
            23 AS suborder
            FROM dm.metadata_crf_ig_item AS mcii
            INNER JOIN dm_metadata_study AS dms
                ON mcii.study_name = dms.study_name
            WHERE 
                EXISTS (
                    SELECT 
                        item_oid 
                    FROM dm.response_set_labels AS drsl
                    WHERE mcii.item_oid = drsl.item_oid
                )
                AND mcii.item_data_type = 'INT'
            
            /* FORMAT ALL STRINGS - DISPLAY AS %20s */
            UNION ALL
            SELECT DISTINCT ON (item_group_oid)
                $line$quietly ds, has(type string)$line$,
                lower(item_group_oid) AS relname,
                24 AS suborder
            FROM dm.metadata_crf_ig_item AS mcii
            INNER JOIN dm_metadata_study AS dms
                ON mcii.study_name = dms.study_name
            UNION ALL
            SELECT DISTINCT ON (item_group_oid)
                $line$quietly format `r(varlist)' %20s$line$,
                lower(item_group_oid) AS relname,
                25 AS suborder
            FROM dm.metadata_crf_ig_item AS mcii
            INNER JOIN dm_metadata_study AS dms
                ON mcii.study_name = dms.study_name
        ), item_group_rows AS (
            SELECT 
                concat(
                    $line$odbc load, exec("SELECT *$line$,
                    format($line$ FROM %1$s.%2$s `data_filter_string'")$line$,
                        filter_study_name_schema,
                        relname
                    ),
                    $line$ connectionstring("`odbc_string_or_file_dsn_path'")$line$
                ) AS statements,
                relname_substr AS relname,
                10 AS suborder
            FROM views
            WHERE views.relkind = $$v$$
            UNION ALL
            SELECT 
                cmd AS statements,
                relname,
                suborder
            FROM label_cmds
            UNION ALL
            SELECT 
                format(
                    $line$save "`snapshotdir'/%1$s.dta"$line$,
                    relname_substr
                ) AS statements,
                relname_substr AS relname,
                30 AS suborder
            FROM views
            WHERE views.relkind = $$v$$
            UNION ALL
            SELECT
                $line$clear$line$ AS statements,
                relname_substr AS relname,
                40 as suborder
            FROM views
            WHERE views.relkind = $$v$$
        ), common_matview_rows AS (
            SELECT 
                concat(
                    $line$odbc load, exec("SELECT *$line$,
                    format($line$ FROM %1$s.%2$s `data_filter_string'")$line$,
                        filter_study_name_schema,
                        relname
                    ),
                    $line$ connectionstring("`odbc_string_or_file_dsn_path'")$line$
                ) AS statements,
                relname,
                1 AS suborder
            FROM views
            WHERE views.relkind = $$m$$
                AND views.relname NOT LIKE $$ig_%$$
            UNION ALL
            SELECT 
                $line$quietly ds, has(type string)$line$,
                relname,
                2 AS suborder
            FROM views
            WHERE views.relkind = $$m$$
                AND views.relname NOT LIKE $$ig_%$$
            UNION ALL
            SELECT 
                $line$quietly format `r(varlist)' %20s$line$,
                relname,
                3 AS suborder
            FROM views
            WHERE views.relkind = $$m$$
                AND views.relname NOT LIKE $$ig_%$$
            UNION ALL
            SELECT 
                format(
                    $line$save "`snapshotdir'/%1$s.dta"$line$,
                    relname
                ) AS statements,
                relname,
                4 AS suborder
            FROM views
            WHERE views.relkind = $$m$$
                AND views.relname NOT LIKE $$ig_%$$
            UNION ALL
            SELECT
                $line$clear$line$ AS statements,
                relname,
                5 as suborder
            FROM views
            WHERE views.relkind = $$m$$
                AND views.relname NOT LIKE $$ig_%$$
        )
        SELECT
            statements
        FROM (
            SELECT
                hr.statements,
                1 AS ordering,
                '' AS relname,
                1 AS suborder
            FROM header_rows AS hr
            UNION ALL
            SELECT
                ig.statements,
                2 AS ordering,
                ig.relname,
                ig.suborder
            FROM item_group_rows AS ig
            UNION ALL
            SELECT
                cm.statements,
                3 AS ordering,
                cm.relname,
                cm.suborder
            FROM common_matview_rows AS cm
            WHERE cm.relname IN ('subjects', 'subject_groups', 
                    'metadata_event_crf_ig', 'metadata_crf_ig_item', 
                    'response_set_labels', 'timestamp_data', 'timestamp_schema')
        ) AS unions
        ORDER BY ordering, relname, suborder;
        RETURN;
    END;
    $BODY$
LANGUAGE plpgsql STABLE;