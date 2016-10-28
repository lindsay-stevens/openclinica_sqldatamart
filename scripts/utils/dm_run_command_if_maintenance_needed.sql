CREATE OR REPLACE FUNCTION openclinica_fdw.dm_run_command_if_maintenance_needed(
  maintenance_command TEXT)
RETURNS VOID AS $b$

/* 
Run a maintenance command if needed.

The decision to run commands or not is determined by the results from running
openclinica_fdw.dm_create_should_run_maintenance_table, which are stored in
openclinica_fdw.should_run_maintenance. It is assumed that the table exists.
*/

DECLARE 
  should_run boolean;

BEGIN

SELECT update_needed INTO should_run FROM openclinica_fdw.should_run_maintenance;

IF (should_run) THEN
  EXECUTE maintenance_command;
END IF;

END $b$ LANGUAGE plpgsql VOLATILE;
