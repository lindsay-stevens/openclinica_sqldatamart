# Changelog

## (HEAD -> master)
- [b85028a](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/b85028a82699adb1e7fb6d09ec0fbd77bd7d1c81) doc: add commit view links manually in script

## (github/master)
- [7408f24](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/7408f24cbaac6135a3d76fe1ea0d2ddfee5832b7) chg: link for changelog in main docs readme
- [908a282](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/908a28267b09e284578bee6209ce1a0cb7e60699) new: generated changelog for overview of changes
- [51cde68](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/51cde688e227212a4ae4265e90e73da3237c326a) new: script for generating lazy changelog
- [cb3cc5f](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/cb3cc5f824937f6b294894939afcd6d7048597e5) add link to docs to main readme
- [3c9fde7](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/3c9fde7cd343da6b16ac6312f7cd23f85d090fb0) add file extension to index items so that links will work
- [e9aa4be](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/e9aa4be2dcf9f8d907bff33106a45e1b683cac43) organise docs into folders and put index as readme
- [735fac8](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/735fac8b75c240302790d4b017ba6d7e4b9ac772) add wiki files to the main repository

## (tag: 2015.004)
- [d586d51](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/d586d518cca863a5dc690f45f0bcf48b8e50a005) bump version number
- [6a6f7a5](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/6a6f7a5ec7049ab0938b9c8b8332f254f1537fc4) update stata snapshot function to include labelling commands
- [5375fbe](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/5375fbe9ed13b530a68bb8610ff2311d5609ca24) tidy up stata script odbc load lines to remove excess whitespace from output
- [bf08753](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/bf0875368b8128ba0bf1b6cfd76506baa118ae2f) change dollar quotes to single quotes as pg didn't seem to like it otherwise, ..
- [1986bfb](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/1986bfb880bcc6a882fb0d20353f5e47b7dc0a61) updated item value case to nullify whitespace strings as well as empty strings
- [9562839](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/95628390cb9d7cf9c6e0b6a0d35709bd637869ac) add stata label generator script

## (tag: 2015.003, github/dev, dev)
- [ee500a9](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/ee500a9b9bb4a0b5890db930d494eec3f4258049) bump version number
- [b42ccf1](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/b42ccf1ec576caf6d1f09b6451cbdf415bfa8e94) fix distinct on list in subject_event_crf_status

## (tag: 2015.002)
- [0e65e64](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/0e65e64267c5d9b27e6d18fdbd1e6c4c19601a95) update version
- [0950323](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/0950323cc0e14c46dd5bd853ceeb29f9fc017ac8) updated create_itemgroup_matviews filter to match the av_ prefixed name of views
- [8238ec6](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/8238ec633963e8978cbcbaf030b051d230a2d3e8) move images to wiki
- [3b02406](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/3b0240617ca7789a9be5f602492c5d5102461294) update subject_groups with missing details
- [613f049](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/613f049e282aa4736cde0b79008ef34876dbc440) update dm_metadata; when selecting the items to generate extra multi items, ch..
- [eb8f41e](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/eb8f41e69a0d77d69264b6a52146bec777083cd4) add access make queries module, move all client stuff into clients folder
- [21a6c2a](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/21a6c2a64bac5eb81166c639a215c24e10b1aec8) update setup_sqldatamart; since the functions were split up, run each script b..
- [c224983](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/c224983a5546b4cb78d376ef03ef2d724872ee31) update dm_build_commands; make datamart_admin_role_name a variable argument, m..
- [051e244](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/051e2441cf694fb9739e41545211d9d19f929b02) update dm_grant_study_schema_access to use metadata_study instead of distinct ..
- [f26163f](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/f26163fe229d09b3d0340815eb24b2453742dc34) update dm_drop_study_schema_having_new_def to use metadata_study and metadata_..
- [19db443](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/19db443c6f73cc1c69d1f41cc4418acc342cd351) add dm_drop_schema as this option was removed from dm_create_study_schemas
- [f86ce1d](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/f86ce1d3f802202cd4827ad646d9e3f995541717) update create study schemas; use metadata_study instead of distinct on metadat..
- [ea987cb](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/ea987cb8eef1e64063e819a0777b893575b71f96) update itemgroup_matviews;only create objects that dont exist already,use ..
- [7c81145](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/7c811456badcdaa81385bef4b080db7139ea7145) change common study matviews to use metadata_study instead of distinct and add..
- [a33b545](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/a33b545e12e42da73bf5ed650490f8b44815c9cd) revert changes to dm queries that were part of an unfinished update
- [23d2629](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/23d26290409f4131566f5f92e0ad66055add22e0) split dm_functions by function into separate files
- [d72f1b7](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/d72f1b733ab7d17e2ce9b974f3bde50d49e449af) start splitting up dm_functions
- [11d8e77](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/11d8e77ba48d537001117099df078fffc63ee731) remove wiki link for now
- [893571d](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/893571d09cc75a570b732f464dcadc207d536595) change readme from rst to md so it displays
- [b86b39a](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/b86b39af4670d33729db4a8b1fb98788f95650ed) add readme, move manual to wiki
- [6c02650](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/6c0265066f31a2c731cf228739ba03e0558fab22) add gitignore and license

## (tag: 2015.001)
- [7628103](https://github.com/lindsay-stevens-kirby/openclinica_sqldatamart/commit/76281030ddba1a58fa965d3f2f0e66464d10326f) initial commit of 2015.001

