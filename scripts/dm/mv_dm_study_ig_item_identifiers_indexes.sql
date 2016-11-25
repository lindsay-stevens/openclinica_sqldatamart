CREATE UNIQUE INDEX dm_study_ig_item_identifiers_unique
  ON dm.study_ig_item_identifiers
  USING BTREE (item_group_id, item_ordinal_per_ig_over_crfv, item_multi_order_over_rsi);
CREATE INDEX dm_study_ig_item_identifiers_item_id
  ON dm.study_ig_item_identifiers
  USING BTREE (item_id);
CREATE INDEX IF NOT EXISTS dm_study_ig_item_identifiers_imoor
  ON dm.study_ig_item_identifiers
  USING BTREE (item_multi_order_over_rsi);
CREATE INDEX IF NOT EXISTS dm_study_ig_item_identifiers_study_id
  ON dm.study_ig_item_identifiers
  USING BTREE (study_id);
CREATE INDEX IF NOT EXISTS dm_study_ig_item_identifiers_item_oid
  ON dm.study_ig_item_identifiers
  USING BTREE (item_oid);