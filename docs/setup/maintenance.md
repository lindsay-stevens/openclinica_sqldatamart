# Maintenance Setup


## Dependencies
- pgAgent (or any other job scheduling software)


## Summary
On OCDM server:
- [Install pgAgent](#install-pgagent)
- [Configure pgAgent](#configure-pgagent)
  + [Basic Setup](#basic-setup)
  + [Advanced Setup](#advanced-setup)
- [Start the postgres *pgAgent* service](#start-the-postgres-*pgagent*-service)
- [Create pgAgent Job to Update Database](#create-pgagent-job-to-update-database)

The same steps can be run using another job scheduler, as long each step runs 
in it's own transaction, with the previous one committed before the next one 
starts.


## Install pgAgent
Re-launch the postgreSQL stackbuilder installer, or get the separate pgAgent 
installer from the pgAgent website.


## Configure pgAgent


### Basic Setup
For the basic setup, the default install will run jobs as the postgres 
superuser. The only setup to check is that the service binPath has the correct 
details. See the below section for Advanced setup on updating the binPath.


### Advanced Setup
For the advanced setup, the domain service account will be used to run jobs. 
This role requires *CREATEROLE* privilege as mananging roles is one of the 
maintenance tasks.

- Run the following commands to create the domain service account user:

```sql
CREATE ROLE myDomainServiceAccountName LOGIN
    NOSUPERUSER INHERIT NOCREATEDB CREATEROLE NOREPLICATION;
GRANT pgagent TO myDomainServiceAccountName;
GRANT dm_admin TO myDomainServiceAccountName;
```

- Update the pgAgent binPath to refer to this user, by opening an 
  Administrator command prompt and entering the following command.

```
sc config pgAgent binPath= "C:\Program Files (x86)\pgAgent\bin\pgagent.exe RUN pgAgent -t 600 host=localhost port=5433 user=myDomainServiceAccountName dbname=postgres"
```


The "-t" parameter is the how often, in seconds, that the pgAgent service 
will connect to the database to check for scheduled or requested jobs. The 
above setting of 600 is every 10 minutes. If "postgresql.conf" has logging of 
all statements logging turned on, the pgAgent polling connections will generate 
about 500kB of largely useless log data per day, so the frequency should be 
appropriate to the jobs created.


## Start the postgres *pgAgent* service
- Open services.msc and start the *pgAgent* service.


## Create pgAgent Job to Update the Database
To keep the data up to date, the materialized views must be refreshed. So that 
the data is correct, this should be done in the order they were created. The 
database also needs to be updated when new studies are created. So that this 
happens automatically:

- create a pgAgent job with the following settings:

```
Name: openclinica_fdw_db_refresh
Enabled: True
Job Class: Data import
Host agent: myOCDM_FQDN
```


- create the following job step for this job:

```
Name: step1_openclinica_fdw
Enabled: True
Connection Type: Local
Database: openclinica_fdw_db
Kind: SQL
On Error: Fail
Definition: 
    TABLE dm.refresh_matviews_openclinica_fdw
```

- create additional job steps with the same settings as above, except for 
*Name* and *Definition*, as follows:

```
Name: step2_dm
Definition:
    /* set query planner params that improve execution time */
    SET LOCAL seq_page_cost = 0.25; /* affects dm.metadata */
    SET LOCAL join_collapse_limit = 1; /* affects dm.clinicaldata */
    TABLE dm.refresh_matviews_dm;
```
```
Name: step3_study
Definition:
    TABLE dm.refresh_matviews_study
```
```
Name: step4_rebuild_study
Definition: 
    SELECT openclinica_fdw.dm_drop_study_schema_having_new_definitions();
    /* next few commands committed individually, otherwise 'out of shared memory' */
    /* switch to dm_admin so that it owns all created objects */
    SET ROLE dm_admin;
    /* create study schemas that don't already exist */
    BEGIN;
    SELECT openclinica_fdw.dm_create_study_schemas();
    COMMIT;
    /* create copy of dm matviews in for each study, filtered for that study */
    BEGIN;
    SELECT openclinica_fdw.dm_create_study_common_matviews();
    COMMIT;
    /* create item group matviews */
    BEGIN;
    SELECT openclinica_fdw.dm_create_study_itemgroup_matviews();
    COMMIT;
    /* create item group aliases views */
    BEGIN;
    SELECT openclinica_fdw.dm_create_study_itemgroup_matviews(TRUE);
    COMMIT;
    /* reset role as dm_admin doesn't have privileges for the next bit */
    RESET ROLE;
    /* create study roles */
    SELECT openclinica_fdw.dm_create_study_role();
    /* grant access to the study schema to the study role */
    SELECT openclinica_fdw.dm_grant_study_schema_access_to_study_role();
    /* if built with datamart_admin_role_name not set to the default of 
       'dm_admin', the role name must be provided as a string in the following 
       function, e.g. SELECT dm_reassign_owner_study_matviews('myrolename');
    */
```
```
Name: step5_user_management
Definition:
    TABLE dm.user_management_functions;
```

- create a schedule for the pgAgent job, with the following settings:

```
Name: openclinica_fdw_db_refresh_schedule
Enabled: True
Start: theCurrentDate
End: Blank
Days: All
Month Days: All
Months: All
Hours: All
Minutes: 30
```

The scheduled frequency should be adjusted depending on the time the job takes 
to complete, and how much performance impact there is on the live server.