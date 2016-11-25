/* DataMart foreign data wrapper role and privileges. */
CREATE ROLE openclinica_select NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE openclinica TO openclinica_select;
GRANT USAGE ON SCHEMA public TO openclinica_select;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO openclinica_select;

/* Performance indexes. */
CREATE INDEX IF NOT EXISTS openclinica_fdw_item_form_meta_item_id
  ON item_form_metadata
  USING BTREE (item_id);
CREATE INDEX IF NOT EXISTS openclinica_fdw_item_form_meta_rs_id
  ON item_form_metadata
  USING BTREE (response_set_id);
CREATE INDEX IF NOT EXISTS openclinica_fdw_event_crf_version_id
  ON event_crf
  USING BTREE (crf_version_id);
CREATE INDEX IF NOT EXISTS openclinica_fdw_item_data_usable
  ON item_data
  USING BTREE (item_data_id)
  WHERE value != $$$$ AND status_id NOT IN (5, 7);
