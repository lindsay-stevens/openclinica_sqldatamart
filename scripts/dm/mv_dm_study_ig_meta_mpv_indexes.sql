CREATE UNIQUE INDEX dm_study_ig_meta_mpv_unique
  ON dm.study_ig_meta_mpv USING btree (item_group_id, item_id);