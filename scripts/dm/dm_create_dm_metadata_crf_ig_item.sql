CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_dm_metadata_crf_ig_item()
  RETURNS VOID AS
$b$
/*
Study metadata; crf, item group and item group levels.

Useful for understanding the structure and content of item group data sets.
*/
DECLARE
  column_list TEXT;
  column_filter TEXT DEFAULT $r$^(study|crf|item_group|item).*$r$;
BEGIN
SELECT
  trim(BOTH $s$, $s$ FROM string_agg(s.attname, $s$, $s$)) AS column_list
  INTO column_list
FROM (
  SELECT
    pga.attname
  FROM pg_catalog.pg_attribute AS pga
  WHERE
    pga.attrelid = cast('dm.metadata' AS regclass)
    AND pga.attnum > 0
    AND NOT pga.attisdropped
    AND pga.attname ~ column_filter
  ORDER BY attnum
) as s;
EXECUTE format($q$
    CREATE VIEW dm.metadata_crf_ig_item AS
    SELECT DISTINCT ON (
      study_id,
      crf_version_id,
      item_group_id,
      item_id,
      item_multi_order_over_rsi
    )
      %1$s
    FROM dm.metadata;
  $q$, column_list);
END;
$b$ LANGUAGE plpgsql VOLATILE;