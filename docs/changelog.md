# Changelog

## (HEAD -> master)
- 51cde68 new: script for generating lazy changelog

## (github/master)
- cb3cc5f add link to docs to main readme
- 3c9fde7 add file extension to index items so that links will work
- e9aa4be organise docs into folders and put index as readme
- 735fac8 add wiki files to the main repository

## (tag: 2015.004)
- d586d51 bump version number
- 6a6f7a5 update stata snapshot function to include labelling commands
- 5375fbe tidy up stata script odbc load lines to remove excess whitespace from output
- bf08753 change dollar quotes to single quotes as pg didn't seem to like it otherwise, ..
- 1986bfb updated item value case to nullify whitespace strings as well as empty strings
- 9562839 add stata label generator script

## (tag: 2015.003, github/dev, dev)
- ee500a9 bump version number
- b42ccf1 fix distinct on list in subject_event_crf_status

## (tag: 2015.002)
- 0e65e64 update version
- 0950323 updated create_itemgroup_matviews filter to match the av_ prefixed name of views
- 8238ec6 move images to wiki
- 3b02406 update subject_groups with missing details
- 613f049 update dm_metadata; when selecting the items to generate extra multi items, ch..
- eb8f41e add access make queries module, move all client stuff into clients folder
- 21a6c2a update setup_sqldatamart; since the functions were split up, run each script b..
- c224983 update dm_build_commands; make datamart_admin_role_name a variable argument, m..
- 051e244 update dm_grant_study_schema_access to use metadata_study instead of distinct ..
- f26163f update dm_drop_study_schema_having_new_def to use metadata_study and metadata_..
- 19db443 add dm_drop_schema as this option was removed from dm_create_study_schemas
- f86ce1d update create study schemas; use metadata_study instead of distinct on metadat..
- ea987cb update itemgroup_matviews;only create objects that dont exist already,use ..
- 7c81145 change common study matviews to use metadata_study instead of distinct and add..
- a33b545 revert changes to dm queries that were part of an unfinished update
- 23d2629 split dm_functions by function into separate files
- d72f1b7 start splitting up dm_functions
- 11d8e77 remove wiki link for now
- 893571d change readme from rst to md so it displays
- b86b39a add readme, move manual to wiki
- 6c02650 add gitignore and license

## (tag: 2015.001)
- 7628103 initial commit of 2015.001

