CREATE OR REPLACE FUNCTION openclinica_fdw.dm_create_should_run_maintenance_table(
  cache_age_tolerance_lower TEXT DEFAULT $$15 minutes$$ :: TEXT,
  cache_age_tolerance_upper TEXT DEFAULT $$2 hours$$ :: TEXT)
RETURNS VOID AS $b$

/* 
Create a table with the result of a check of whether maintenance should be run.

Parameters.
- cache_age_tolerance_lower: a string representation of an interval. The minimum 
  amount of time to wait to refresh cached data after activity in the live database.
- cache_age_tolerance_upper: a string representation of an interval. The maximum 
  age of the most recently updated study schema timestamp_data.

Description.
Decides whether maintenance is necessary, based on indications of database 
activity, and how recently the study schema data was updated. A table created 
named openclinica_fdw.should_run_maintenance is created which contains the 
result. The intended use is:

- At the start of maintenance, drop the table if it exists,
- Run this function to evaluate the check and store the results,
- Execute maintenance tasks only if the "update_needed" field is true.

The motivation for this check is to allow scheduling maintenance at a relatively 
high frequency (e.g. every 15 minutes), but have it adapt to user activity. The 
defined tolerance range is 15 minutes to 2 hours. So during periods of sustained 
use, DataMart will be at most (approx.) 15 minutes behind live; in idle periods 
updates are reduced to (approx.) 2-hourly since there is nothing significant to 
update.

The field "update_needed" is true if either or both of the following criteria 
are met:

- Signs of activity (listed below). Check for the latest of these in both the 
  live database and the locally cached data. If the latest from the cached 
  data is more than 30 minutes older than live, this criterion is met.
    - Study or site created or modified,
    - Event definition created or modified,
    - CRF version (including new CRFs) created or modified,
    - Rule definition created or modified,
    - User account created, modified, or used to login in,
    - Audit log entry added (catches all data entry operations),
    - Discrepancy note thread created or response added,
    - Extract dataset created, modified or run.
- Check all the study schema timestamp_data values. If the latest of these is 
  more than 2 hours old, this criterion is met.
    - In the event that the above doesn't cover all relevant indications 
      of user activity, we can at least be assured that all the data is being 
      refreshed every 2 hours.
    - When a schema is rebuilt, the data is refreshed as well, so we don't need
      perform the same kind of check with the study timestamp_schema views.

The data used in performing this check is sent to the postgres logs.

*/

DECLARE
  cached_age_over_lower_cmp_live boolean;
  latest_activity_live timestamptz;
  latest_activity_cached timestamptz;
  latest_activity_cached_compared timestamptz;
  
  latest_timestamp_data_sql text;
  latest_timestamp_data timestamptz;
  timestamp_data_over_upper boolean;
  
  should_run boolean;
  command_run_message text;

BEGIN

/* Run the activity check query. */
/* Role change required to access foreign data. */ 
SET ROLE dm_admin;

/* This is a bit repetitive but much clearer than an equivalent query 
   constructed with nested format() calls. */
EXECUTE format($q$
SELECT
  greatest_cached + interval %1$L < greatest_live,
  greatest_live,
  greatest_cached,
  greatest_cached + interval %1$L
FROM (
  SELECT 
    greatest(
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.ft_study),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.ft_study_event_definition),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.ft_crf_version),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.ft_rule),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz, 
        max(date_lastvisit)::timestamptz)
      FROM openclinica_fdw.ft_user_account),
      (SELECT max(audit_date)::timestamptz
      FROM openclinica_fdw.ft_audit_log_event),
      (SELECT max(date_created)::timestamptz
      FROM openclinica_fdw.ft_discrepancy_note),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz, 
        max(date_last_run)::timestamptz)
      FROM openclinica_fdw.ft_dataset)) AS greatest_live,
    greatest(
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.study),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.study_event_definition),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.crf_version),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz) 
      FROM openclinica_fdw.rule),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz, 
        max(date_lastvisit)::timestamptz)
      FROM openclinica_fdw.user_account),
      (SELECT max(audit_date)::timestamptz
      FROM openclinica_fdw.audit_log_event),
      (SELECT max(date_created)::timestamptz
      FROM openclinica_fdw.discrepancy_note),
      (SELECT greatest(
        max(date_created)::timestamptz, 
        max(date_updated)::timestamptz, 
        max(date_last_run)::timestamptz)
      FROM openclinica_fdw.dataset)) AS greatest_cached
) AS greatest_sub;
$q$, cache_age_tolerance_lower)
  INTO cached_age_over_lower_cmp_live, latest_activity_live, 
    latest_activity_cached, latest_activity_cached_compared;
RESET ROLE;


/* Build and execute the study timestamp_data check query. */
SELECT string_agg(select_timestamp_data, ', ') INTO latest_timestamp_data_sql
FROM (
  SELECT 
    format($f$(SELECT timestamp_data FROM %1$I.%2$I)$f$,
      schemaname, matviewname) AS select_timestamp_data
  FROM pg_catalog.pg_matviews
  WHERE matviewname = $i$timestamp_data$i$
) AS sub_statements;

EXECUTE format($q$
SELECT 
  greatest(%1$s) + interval %2$L < now(), 
  greatest(%1$s);
$q$, latest_timestamp_data_sql, cache_age_tolerance_upper)
  INTO timestamp_data_over_upper, latest_timestamp_data;

/* Store the outcome and log the details. */
should_run := cached_age_over_lower_cmp_live OR timestamp_data_over_upper;
EXECUTE format($q$
  CREATE TABLE openclinica_fdw.should_run_maintenance AS 
    SELECT CAST(%1$L AS boolean) AS update_needed, now() AS last_checked;
  $q$, should_run);

IF should_run THEN
  command_run_message = $s$Maintenance commands were run. Database appeared to be out of date.$s$;
ELSE
  command_run_message = $s$Maintenance commands were skipped. Database appeared to be up to date.$s$;
END IF;

RAISE LOG '%', concat_ws($s$|$s$, command_run_message, 
  $s$ should run $s$, should_run,
  $s$ cached over lower $s$, cached_age_over_lower_cmp_live, 
  $s$ latest live $s$, latest_activity_live,
  $s$ cached compared $s$, latest_activity_cached_compared,
  $s$ latest cached $s$, latest_activity_cached,
  $s$ timestamp_data over upper $s$, timestamp_data_over_upper,
  $s$ timestamp_data $s$, latest_timestamp_data);

END $b$ LANGUAGE plpgsql VOLATILE;
