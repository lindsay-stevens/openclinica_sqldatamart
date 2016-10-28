# Maintenance Setup


## Contents
- [Introduction](#introduction)
    - [Other Schedulers](#other-schedulers)
- [Installation](#installation)
    - [Troubleshooting](#troubleshooting)
    - [Where to Get the pgAgent Installer](#where-to-get-the-pgagent-installer)
- [Configuration](#configuration)
    - [User Accounts](#user-accounts)
        - [User Accounts: Basic](#user-accounts-basic)
        - [User Accounts: Advanced](#user-accounts-advanced)
    - [pgAgent Check Frequency (Optional)](#pgagent-check-frequency-optional)
    - [pgAgent Job Definition](#pgagent-job-definition)
        - [Deciding on Frequency](#deciding-on-frequency)
        - [pgagent Job Definition](#pgagent-job-definition)
- [Checks](#checks)


## Introduction
This document describes the setting up maintenance of the DataMart database. These maintenance tasks will include refreshing / updating the data, creating new or re-creating changed study schemas, and user management. 

All of steps should be done on the server where DataMart is installed, which is referred to as "OCDM" elsewhere in the documentation. These instructions refer to the installation and configuration of PostgreSQL job scheduler tool named "pgAgent".


### Other Schedulers
Since the maintenance tasks are largely driven by functions and queries present in the database, it would be possible to set up maintenance using some other job scheduler, such as Task Scheduler on Windows, or Cron on Linux. 

The main difference in setting up an alternative job scheduler would be that a non-pgAgent setup must manage connecting to the database e.g. using the psql command line tool, psqlODBC, or some other driver; in order to issue the necessary commands.


## Installation
Run the pgAgent installer. During installation, provide the installer with the "postgres" superuser credentials for connection, and your local user credentials for the service. 

If following the "Advanced" setup, the credentials provided during installation will be replaced with dedicated user credentials.


### Troubleshooting
There is a chance that the pgAgent installation may not complete, for example:

- For "Advanced" deployments, the installer may not accept the domain service account (DSA) as the pgAgent service user. Instead, provide your local user name and change it as described in later in this document.
- The database objects for pgAgent to record job information may not have been created in the database, for example if there was a problem connecting to the database during installation (although, the Windows service may still have been created). The pgAgent objects are visible in pgAdmin under "Catalogs" (not "Schemas"). If there is no pgAgent catalog, run the setup SQL script manually as follows:
    - Locate the pgAgent setup script. It should be at: ```C:\Program Files (x86)\pgAgent\share\pgagent.sql```.
    - Execute the script in the default "postgres" database (not the DataMart database!). For example using psql (pgAdmin works too): ```psql -h localhost -p 5433 -U postgres -W -f "C:\Program Files (x86)\pgAgent\share\pgagent.sql"```.


### Where to Get the pgAgent Installer
If using the EDB PostgreSQL distribution, pgAgent is an optional extra that can be installed using the packaged StackBuilder tool. If the pgAgent option was not selected during installation, the StackBuilder tool can be launched from the PostgreSQL installation directory at: ```C:\Program Files\PostgreSQL\9.6\bin\stackbuilder.exe```.


## Configuration


### User Accounts
The following two sections describe user account setup, which depends on whether the "Basic" or "Advanced" setup instructions are being followed.


#### User Accounts: Basic
For the "Basic" setup, the default install will run jobs as the postgres superuser, so you don't need to configure user accounts and can continue to the next step.


#### User Accounts: Advanced
For the "Advanced" setup, the domain service account (DSA) will be used to run jobs. In summary, the tasks to do are:

- Add a role with appropriate privileges for the DSA,
- Update the pgAgent service command with the correct details,
- Update the pgAgent service to run as the DSA.

First, connect to the DataMart database and run the following SQL commands. Replace the user name "datamart" with the local name of your DSA. These SQL commands:

- Create a group role for pgAgent-related privileges,
- Create a login role for the DSA,
- Grant the pgAgent role to the DSA role.

```sql
CREATE ROLE pgagent;
GRANT ALL ON SCHEMA pgagent to pgagent;
GRANT ALL ON ALL TABLES IN SCHEMA pgagent to pgagent;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pgagent to pgagent;
GRANT CONNECT ON DATABASE postgres to pgagent;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pgagent TO pgagent;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pgagent TO pgagent;

/* Replace "datamart" with the domain service account name for your deployment. */
CREATE ROLE datamart LOGIN
    NOSUPERUSER INHERIT NOCREATEDB CREATEROLE NOREPLICATION;
GRANT pgagent TO datamart;
GRANT dm_admin TO datamart;
```

Next, update the pgAgent binPath to refer to this user, by opening an Administrator command prompt and entering the following command. Replace "user=datamart" to refer to the local name of the DSA, and ensure the other environment details are correct. 

```
sc config pgAgent binPath= "C:\Program Files (x86)\pgAgent\bin\pgagent.exe RUN pgAgent host=localhost port=5433 user=datamart dbname=postgres"
```


### pgAgent Job Check Frequency (Optional)
By default, pgAgent connects to PostgreSQL every 60 seconds to check for jobs that are scheduled to be executed. If logging all database connections as per the "Advanced" setup, this amount of traffic will generate about 500KB of logs per day. This is especially unnecessary if for example the maintenance frequency is set to run every hour.

To configure the check frequency, the pgAgent service command must be updated to add a "-t" parameter, which is how often in seconds to reconnect, e.g. "-t 600" means that pgAgent will check for jobs every 10 minutes. 

To update the pgAgent service command:

- Check that the details in the command shown below are correct for your deployment environment.
    - "Advanced" setups should add the "user=DSA" parameter described in the above section.
- Open an Administrator command prompt. To do this, press the Windows key, then type "cmd", then right-click click on the search result "cmd.exe", and click "Run as Administrator".
- Run the following command: 

```
sc config pgAgent binPath= "C:\Program Files (x86)\pgAgent\bin\pgagent.exe RUN pgAgent -t 600 host=localhost port=5433 dbname=postgres"
```


### pgAgent Job Definition
So that pgAgent knows what to do, we must create a job definition in the maintenance database (where pgAgent was installed, by default it is "postgres"). The definition will contain information like the target database details, when to run the jobs, and what steps should be executed.

Job definitions can be created either interactively via pgAdmin, or by loading an SQL script. The following two sections describe how to do both.


#### Deciding on Frequency
There are two main components to defining job frequency:

- How often will the tasks be executed: defined by a function in job step 2,
- How often will pgAgent the job: defined by the pgAgent job schedule.

The function is named "dm_create_should_run_maintenance_table", and sets a lower and upper range on refresh frequency. The lower range translates into "how soon after some activity in the live database should DataMart be updated?". The upper range translates into "how old can the most recently updated study schema be before it must be updated?" - this may seem counterintuitive but all study schemas that aren't for locked studies are updated together.

The job schedule interacts with this and should be nearer to lower end of the frequency range defined in the function. The default configuration is: schedule every 15 minutes, lower range 15 minutes, upper range 2 hours. This means that during active use, DataMart will be updated about every 15 minutes. During idle periods, this falls back down to 2 hours.

Selecting a good combination of these intervals requires a little bit of experimentation; considerations include:

- How long does it take to complete all maintenance jobs?
    - Affected by server resources (CPU, RAM, etc.), quantity of data (amount of studies and data points in them).
    - Schedule should be set to run at a frequency that is longer than the time it takes to complete once over.
    - A database with 1 million rows in item_data across 15 studies, with 2 CPUs and 4GB RAM on Windows takes about 5 minutes to complete all maintenance tasks.
- How often does the data need to be updated?
    - For small OpenClinica instances with few users or studies, it may be acceptable to only update every 3 hours or so, thereby saving server resources. Or due to the smaller amount of data it may be preferable to update every 10 minutes or less.
    - For very large OpenClinica instances with hundreds of users and studies, depending on the server hardware, there may be some performance impact on the OpenClinica application (untested), which requires a lower frequency.


#### pgagent Job Definition
It is possible to create pgAgent job definitions interactively, via the pgAgent interface. However, it is considerably faster to create it using an SQL script. 

The default details must be modified to suit the environment. This can be done in the SQL script before loading it, or the values can be edited interactively in pgAdmin.

To create the job definition using the SQL script:

- Locate the SQL script at "docs/setup/maintenance_pgagent_config.sql",
- Update the details in the script, or do so in pgAdmin after loading it,
- Connect to the maintenance database (where pgAgent was installed) to run the script:
    - In pgAdmin, connect to the postgres database, open the query tool, copy and paste in the SQL script and run it, or
    - Load it using psql:

```psql -h localhost -p 5433 -d postgres -U postgres -W -f "maintenance_pgagent_config.sql"```

## Checks
The following should be checked to make sure that the maintenance setup is OK:

- The pgAgent service is running: status can be checked:
    - On the command line with ```sc query pgagent```, or 
    - By launching the service manager: ```services.msc```.
- pgAgent has been able to connect to PostgreSQL: 
    - If logging all connections, check the postgres logs which by default are saved at ```C:\Program Files\PostgreSQL\9.6\data\pg_log``` and look for connection attempts by the pgAgent user (either postgres for "Basic" or the DSA for "Advanced" setup).
    - If not logging all connections, either watch / re-query the view "pg_catalog.pg_stat_activity", or in pgAdmin go to "Tools" then "Server status" and watch for connection attempts.
- Jobs are being successfully completed.
    - In pgAdmin, go to "Jobs", select the openclinica refresh job, and in the "Statistics" tab, check that the status on jobs is all "Successful", or
    - Use psql to retrieve a log listing, as shown below.
    
```psql -h localhost -p 5433 -U postgres -d postgres -W -c "SELECT j.jobname, l.jlgstatus, l.jlgstart, l.jlgstart + l.jlgduration AS job_end, l.jlgduration FROM pgagent.pga_joblog AS l INNER JOIN pgagent.pga_job AS j ON j.jobid = l.jlgjobid"```

If you run in to trouble with these checks and can't figure it out, feel free to open an issue on GitHub to get some help.
