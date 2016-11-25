/* Heavily used reference table, benefits from indexing. */
CREATE INDEX dm_response_sets_response_type_id
  ON dm.response_sets USING btree (response_type_id);
CREATE INDEX dm_response_sets_option_value
  ON dm.response_sets USING btree (option_value);
CREATE INDEX dm_response_sets_set_id_version_id
  ON dm.response_sets USING btree (response_set_id, version_id);
CREATE UNIQUE INDEX dm_response_sets_unique
  ON dm.response_sets USING btree (response_set_id, option_order);