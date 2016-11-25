CREATE UNIQUE INDEX dm_study_ig_metadata_unique
  ON dm.study_ig_metadata
  USING BTREE (item_group_id, item_id, item_multi_order_over_rsi);
CREATE INDEX IF NOT EXISTS dm_study_ig_metadata_imoor
  ON dm.study_ig_metadata
  USING BTREE (item_multi_order_over_rsi);
CREATE INDEX IF NOT EXISTS dm_study_ig_metadata_irsid_crfid
  ON dm.study_ig_metadata
  USING BTREE (item_response_set_id, crf_version_id);
CREATE INDEX IF NOT EXISTS dm_study_ig_metadata_item_oid
  ON dm.study_ig_metadata
  USING BTREE (item_oid);
CREATE INDEX IF NOT EXISTS dm_study_ig_metadata_idt_id
  ON dm.study_ig_metadata
  USING BTREE (item_data_type_id);