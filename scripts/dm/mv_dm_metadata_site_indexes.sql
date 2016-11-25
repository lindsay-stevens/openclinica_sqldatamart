CREATE UNIQUE INDEX dm_metadata_site_unique
  ON dm.metadata_site USING btree (site_id);