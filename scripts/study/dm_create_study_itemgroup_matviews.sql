CREATE OR REPLACE FUNCTION openclinica_fdw.create_study_itemgroup_matviews(
  IN  alias_views              BOOLEAN DEFAULT FALSE,
  IN  filter_study_schema_name TEXT DEFAULT $$$$ :: TEXT,
  IN  filter_item_group_oid    TEXT DEFAULT $$$$ :: TEXT,
  OUT done_message             TEXT)
AS $b$
DECLARE
  r RECORD;
BEGIN

  FOR r IN

  SELECT vd.create_statement
  FROM dm.study_ig_viewdefs AS vd
  WHERE
    CASE
    WHEN alias_views
      THEN 'av' = vd.ig_viewtype
    ELSE 'mv' = vd.ig_viewtype
    END
    AND
    CASE
    WHEN length(filter_study_schema_name) > 0
      THEN filter_study_schema_name = vd.study_name_clean
    ELSE TRUE
    END
    AND
    CASE
    WHEN length(filter_item_group_oid) > 0
      THEN filter_item_group_oid = vd.item_group_oid
    ELSE TRUE
    END

  LOOP
    EXECUTE r.create_statement;
  END LOOP;

  done_message := $s$done$s$;

END$b$ LANGUAGE plpgsql VOLATILE;