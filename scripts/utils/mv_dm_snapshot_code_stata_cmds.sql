CREATE MATERIALIZED VIEW dm.snapshot_code_stata_cmds AS
  /*
  All Stata snapshot code commands.

  Function adds the script header and filters these results by study.
  */
  WITH group_footer AS (
    SELECT *
    FROM
      (
        VALUES
          (1, $s$quietly ds, has(type string)$s$),
          (2, $s$quietly format `r(varlist)' %20s$s$),
          (4, $s$clear$s$)
      ) AS t(suborder, cmd_text)

  ), group_sections AS (
    SELECT
      pgn.nspname,
      pgc.relname
    FROM
    pg_catalog.pg_class AS pgc
    INNER JOIN
    pg_catalog.pg_namespace AS pgn
      ON pgc.relnamespace = pgn.oid
    WHERE
      left(pgc.relname, 3) = 'av_'

  ), item_metadata AS (
    SELECT *
    FROM dm.study_id_ident_rejoin

  ), item_group_rows AS (
    SELECT
      nspname,
      format(
        concat($s$odbc load, exec("SELECT * FROM$s$,
               $f$ %1$s.%2$s `data_filter'") $f$,
               $s$connectionstring("`odbc_dsn')" $s$),
        nspname, relname) AS cmd_text,
      relname,
      1 AS suborder
    FROM group_sections

    /* Label variables. Maximum 80 characters for label text. */
    UNION ALL
    SELECT
      nspname,
      format(
        $f$lab var %1$s "%2$s"$f$,
        av_ident_final,
        left(
          concat_ws(
            $s$_$s$, clean_description, clean_item_multi_option_text), 80)
      ) AS cmd,
      item_group_relname,
      2 AS suborder
    FROM item_metadata

    /* Define value labels. Maximum 32000 characters for label text. */
    UNION ALL
    SELECT
      nspname,
      format(
        $f$lab def %1$s_lbl %2$s "%3$s", modify$f$,
        av_ident_final,
        coalesce(rs.option_value, item_multi_option_value),
        left(
          coalesce(
            openclinica_fdw.dm_clean_name_string(rs.option_text),
            clean_item_multi_option_text), 32000)
      ) AS cmd,
      item_group_relname,
      3 AS suborder
    FROM item_metadata
    LEFT JOIN dm.response_sets AS rs
      ON item_metadata.item_response_set_id = rs.response_set_id
         AND item_metadata.crf_version_id = rs.version_id
    WHERE item_data_type_id = 6

    /* Apply value labels */
    UNION ALL
    SELECT
      nspname,
      format(
        $line$lab val %1$s %1$s_lbl$line$,
        av_ident_final
      ) AS cmd,
      item_group_relname,
      4 AS suborder
    FROM item_metadata
    WHERE item_data_type_id = 6

    UNION ALL
    SELECT
      nspname,
      format(
        $f$save "`snapshotdir'/%1$s.dta"$f$,
        substring(relname FROM 4)) AS statements,
      relname,
      5 + 3 AS suborder
    FROM group_sections

    UNION ALL
    SELECT
      nspname,
      group_footer.cmd_text,
      relname,
      5 + group_footer.suborder
    FROM group_sections, group_footer
  ), relevant_studies AS (
    SELECT study_name_clean AS nspname
    FROM dm.metadata_study
    WHERE study_id IN (
      SELECT DISTINCT study_id
      FROM dm.study_ig_metadata)

  ), extra_data AS (
    SELECT
      relevant_studies.nspname,
      t.relname
    FROM (
           VALUES
             ('subjects'),
             ('subject_groups'),
             ('metadata_event_crf_ig'),
             ('metadata_crf_ig_item'),
             ('response_set_labels'),
             ('timestamp_data'),
             ('timestamp_schema')
         ) AS t(relname), relevant_studies

  ), extra_data_rows AS (
    SELECT
      nspname,
      format(
        concat($s$odbc load, exec("SELECT * FROM $s$,
               $f$%1$s.%2$s `data_filter'") $f$,
               $s$connectionstring("`odbc_dsn')" $s$),
        nspname, relname) AS cmd_text,
      relname,
      1 AS suborder
    FROM extra_data

    UNION ALL
    SELECT
      nspname,
      format(
        $f$save "`snapshotdir'/%1$s.dta"$f$,
        relname) AS statements,
      relname,
      2 AS suborder
    FROM extra_data

    UNION ALL
    SELECT
      nspname,
      group_footer.cmd_text,
      relname,
      3 + group_footer.suborder
    FROM extra_data, group_footer
  )

  SELECT
    nspname,
    relname,
    ordering,
    suborder,
    cmd_text
  FROM
    (
      SELECT
        nspname,
        2 AS ordering,
        suborder,
        relname,
        cmd_text
      FROM item_group_rows
      UNION ALL
      SELECT
        nspname,
        3,
        suborder,
        relname,
        cmd_text
      FROM extra_data_rows
    ) AS u
  ORDER BY
    nspname,
    relname NULLS FIRST,
    ordering,
    suborder,
    cmd_text;