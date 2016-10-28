/*
Set up a pgAgent job with DataMart maintenance tasks.

As an alternative to using the pgAdmin UI to configure a job, the following SQL 
will create a job definition in the pgagent extension catalog tables.

Note that the value in the line starting with "my_fqdn" must be updated to match 
the deployment environment. This hostname should be that of the server where 
pgAgent and DataMart are installed. The fqdn value is case-sensitive.
*/


/* Create the job definition, which will have a schedule and steps attached to it.*/
WITH 
  my_fqdn AS (SELECT 'svr-ocdm-pSQL9.ad.nchecr.unsw.edu.au' AS fqdn),
  jobdef AS (
    INSERT INTO pgagent.pga_job (
      jobjclid, jobname, jobhostagent, 
      jobenabled, jobnextrun, joblastrun) 
    VALUES 
      ((SELECT jclid FROM pgagent.pga_jobclass WHERE jclname = 'Routine Maintenance'),
        'openclinica_fdw_db_refresh', (SELECT fqdn FROM my_fqdn), true, now(), NULL)
    RETURNING jobid
  )

/* Create the job steps.
  
  The function dm_run_command_if_maintenance_needed is used to check if the data is 
  has changed recently. If it hasn't, then the command specified as the function 
  argument is not executed.
 */
INSERT INTO pgagent.pga_jobstep (jstname, jstenabled, jstkind, jstdbname, 
  jstonerror, jstjobid, jstcode) 
VALUES 
  ('step1_pre_rollback', true, 's', 'openclinica_fdw_db', 'i', 
    (SELECT jobid FROM jobdef),
    $s$
      ROLLBACK; /* In case last job run died mid-transaction. */
    $s$),
  
  ('step2_check_should_run_maintenance', true, 's', 'openclinica_fdw_db', 'f', 
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      DROP TABLE IF EXISTS openclinica_fdw.should_run_maintenance;
      COMMIT;
      BEGIN;
      SELECT openclinica_fdw.dm_create_should_run_maintenance_table(
        '15 minutes', '2 hours');
      COMMIT;
      BEGIN;
      DO $b$
      BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.tables 
        WHERE table_schema = 'openclinica_fdw'
          AND table_name = 'should_run_maintenance'
      ) THEN
        GRANT ALL ON ALL TABLES IN SCHEMA openclinica_fdw TO dm_admin;
        ALTER TABLE openclinica_fdw.should_run_maintenance OWNER TO dm_admin;
      END IF;
      END$b$;
      COMMIT;
    $s$),
  
  ('step3_refresh_openclinica_fdw', true, 's', 'openclinica_fdw_db', 'f', 
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT * FROM dm.refresh_matviews_openclinica_fdw;
      $c$);
      COMMIT;
    $s$),
  
  ('step4_refresh_dm_matviews', true, 's', 'openclinica_fdw_db', 'f', 
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SET LOCAL seq_page_cost = 0.25;
        SET LOCAL join_collapse_limit = 1;
        SELECT * FROM  dm.refresh_matviews_dm;$c$);
      COMMIT;
    $s$),
  
  ('step5_refresh_study_matviews', true, 's', 'openclinica_fdw_db', 'f',
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT * FROM dm.refresh_matviews_study;$c$);
      COMMIT;
    $s$),
  
  ('step6_rebuild_study_if_needed', true, 's', 'openclinica_fdw_db', 'f',
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_drop_study_schema_having_new_definitions();$c$);
      COMMIT;
      /* Need dm_admin permissions here, e.g. foreign server user mapping, etc. */
      SET ROLE dm_admin;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_create_study_schemas();$c$);
      COMMIT;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_create_study_common_matviews();$c$);
      COMMIT;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_create_study_itemgroup_matviews();$c$);
      COMMIT;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_create_study_itemgroup_matviews(TRUE);$c$);
      COMMIT;
      /* Reset to privileged to create the study group role and grant it access. */
      RESET ROLE;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_create_study_role();$c$);
      COMMIT;
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT openclinica_fdw.dm_grant_study_schema_access_to_study_role();$c$);
      COMMIT;
    $s$),
    
  ('step7_user_management', true, 's', 'openclinica_fdw_db', 'f',
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      SELECT openclinica_fdw.dm_run_command_if_maintenance_needed($c$
        SELECT * FROM  dm.user_management_functions;$c$);
      COMMIT;
    $s$),
    
  ('step8_clean_up', true, 's', 'openclinica_fdw_db', 'f', 
    (SELECT jobid FROM jobdef),
    $s$
      BEGIN;
      DROP TABLE openclinica_fdw.should_run_maintenance;
      COMMIT;
    $s$);


/* Create the job schedule.

  The array values translate into running at: all months (1 to 12), all month 
  days (0 to 31), all week days (Monday to Sunday), all hours (00 to 23), and 
  the first minute of each hour (00 only, out of 00 to 59).
*/
WITH jobdef AS (
  SELECT jobid 
  FROM pgagent.pga_job 
  WHERE jobname = 'openclinica_fdw_db_refresh'
  ORDER BY jobcreated DESC
  LIMIT 1
)
INSERT INTO pgagent.pga_schedule (jscname, jscenabled, jscstart, jscjobid, 
  jscmonths, jscmonthdays, jscweekdays, jschours, jscminutes) 
VALUES 
  ('openclinica_fdw_db_refresh_schedule', true, now(),
    (SELECT jobid FROM jobdef),
    /* MM */'{t,t,t,t,t,t,t,t,t,t,t,t}',
    /* DD */'{t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t}',
    /* E  */'{t,t,t,t,t,t,t}',
    /* HH */'{t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t}',
    /* MM */ '{t,f,f,f,f,f,f,f,f,f,f,f,f,f,f,t,f,f,f,f,f,f,f,f,f,f,f,f,f,f,t,f,f,f,f,f,f,f,f,f,f,f,f,f,f,t,f,f,f,f,f,f,f,f,f,f,f,f,f,f}');
