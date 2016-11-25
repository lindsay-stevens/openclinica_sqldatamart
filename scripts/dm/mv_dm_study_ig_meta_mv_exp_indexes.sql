CREATE UNIQUE INDEX dm_study_ig_meta_mv_exp_unique
  ON dm.study_ig_meta_mv_exp USING btree (item_id, item_multi_order_over_rsi);
CREATE INDEX dm_study_ig_meta_mv_exp_item_id
  ON dm.study_ig_meta_mv_exp USING btree (item_id)