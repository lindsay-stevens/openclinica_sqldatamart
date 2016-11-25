CREATE UNIQUE INDEX dm_metadata_study_unique
  ON dm.metadata_study USING btree (study_id);