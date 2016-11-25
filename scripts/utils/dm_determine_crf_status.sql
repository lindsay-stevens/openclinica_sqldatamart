CREATE OR REPLACE FUNCTION openclinica_fdw.dm_determine_crf_status(
  IN  subject_event_status_id INTEGER,
  IN  crf_version_status_id INTEGER,
  IN  event_crf_status_id INTEGER,
  IN  event_crf_status_name TEXT,
  IN  event_crf_validator_id INTEGER,
  IN  event_def_crf_double_entry BOOLEAN,
  OUT event_crf_display_status TEXT
) AS $b$
/*
Return the event CRF status as it would be displayed in the OpenClinica UI.
*/

SELECT
    CASE
    WHEN subject_event_status_id IN (5, 6, 7) /* stopped,skipped,locked */
      THEN 'locked'
    WHEN crf_version_status_id <> 1 /* available */
      THEN 'locked'
    WHEN event_crf_status_id = 1
      THEN 'initial data entry'
    WHEN event_crf_status_id = 2
      THEN
        CASE
        WHEN event_def_crf_double_entry = TRUE
          THEN 'validation completed'
        WHEN event_def_crf_double_entry = FALSE
          THEN 'data entry complete'
        ELSE 'unhandled'
        END
    WHEN event_crf_status_id = 4 /* pending */
      THEN
        CASE
        WHEN event_crf_validator_id <> 0 /* default zero */
          /* blank if event_crf created by insertaction rule */
          THEN 'double data entry'
        WHEN event_crf_validator_id = 0
          THEN 'initial data entry complete'
        ELSE 'unhandled'
        END
    ELSE event_crf_status_name
    END AS event_crf_display_status
$b$ LANGUAGE SQL IMMUTABLE;