/* add dm matview with study metadata for all itemgroups in all events and studies */
SELECT openclinica_fdw.dm_create_dm_metadata_event_crf_ig();
/* add dm matview with study metadata for all items in all studies */
SELECT openclinica_fdw.dm_create_dm_metadata_crf_ig_item();
/* add dm matview with subjects in all studies */
SELECT openclinica_fdw.dm_create_dm_subjects();
/* add dm matview with event and crf statuses for each subject in each study */
SELECT openclinica_fdw.dm_create_dm_subject_event_crf_status();
/* add dm matview with possible events and crfs for each subject in each study */
SELECT openclinica_fdw.dm_create_dm_subject_event_crf_expected();
/* add dm matview with expected and current event and crf statuses for each subject in each study */
SELECT openclinica_fdw.dm_create_dm_subject_event_crf_join();
/* add dm matview with parent discrepancy notes in each study */
SELECT openclinica_fdw.dm_create_dm_discrepancy_notes_parent();
/* add dm matview with subject groups for each subject in each study */
SELECT openclinica_fdw.dm_create_dm_subject_groups();
/* add dm matview with reponse sets for each item in each crf in each study */
SELECT openclinica_fdw.dm_create_dm_response_set_labels();
/* add dm matview with study roles for each user account in the instance */
SELECT openclinica_fdw.dm_create_dm_user_account_roles();
/* add dm matview with sdv status history for each subject event crf */
SELECT openclinica_fdw.dm_create_dm_sdv_status_history();
