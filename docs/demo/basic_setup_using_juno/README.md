# Demo of Basic Setup Using Juno

## Contents
- [Introduction](#introduction)
    - [Viewing Scripts](#viewing-scripts)
- [Preparation](#preparation)
- [Setup](#setup)
    - [Other Files in the Demo Directory](#other-files-in-the-demo-directory)
- [Further Browsing](#further-browsing)
- [Stata Export](#stata-export)


## Introduction
This folder provides resources for taking Community DataMart for a test drive, using the OpenClinica demo study database called "JUNO".

There are two ways to explore this:

- Look at the previously prepared files under "premade_demo_files", or
- Follow this document to complete the "Basic" setup steps.

The final files include:

- A copy of the JUNO study schema which can be loaded into PostgreSQL 9.6 or later,
    - `psql -d postgres -c "CREATE DATABASE the_juno_diabetes_study;"`
    - `pg_restore -d the_juno_diabetes_study the_juno_diabetes_study.backup`
- A copy of a Stata ".dta" files extracted for the JUNO study,
- Three CSV files with example data (in case you have PostgreSQL troubles),
    - `juno_matviews.csv`: a list of the materialized views that were created,
    - `subjects_listing.csv`: a list of the subjects in the JUNO study,
    - `item_group_example.csv`: an example item group table, "IG_EATIN_HABITS".

To demonstrate the client tools, the Stata extract process is described here, which generates a set of Stata ".dta" files for the JUNO study. Other client tools in DataMart include:

- A SAS script - similar to the Stata script, but without native variable/value labels,
- A Stata script to prepare per-site Excel extracts for study close-out,
- An Access VBA script for generating pass-thru queries for the views in a study.

Instructions and scripts in this document assume you're using Windows 7 or equivalent. For Linux users, please open an issue in GitHub if you'd like a version prepared for Linux.


### Viewing Scripts
The scripts in this directory are best viewed in Notepad++, or an IDE. In Windows Notepad, they'll look like a hot mess. This is because in general, they use Linux line endings. Windows uses different line endings, which Linux doesn't like to run. However, Windows can run scripts that use Linux line endings. The trade off is that it makes scripts look weird in Windows Notepad, which happens to be the default for a lot of plain text files.


[Back to Contents](#contents)


## Preparation
In this demo a throwaway database cluster will be used so that clean up is simply a matter of deleting the "./postgres/data" folder that is created. This folder will be about 100MB in size.

The preparation steps are:

- Install PostgreSQL 9.6 on your machine.
    - 9.3 or later should work but the latest is best.
- Install psqlODBC (latest available version), which is an ODBC driver for PostgreSQL.
    - This can be installed with PostgreSQL if using the EDB distribution of PostgreSQL.
    - Available separately at: https://www.postgresql.org/ftp/odbc/versions/msi/
- Right-click -> Edit the file `demo0_set_pg_install_path.bat`. 
    - Update the PostgreSQL installation path in this file if it is not correct.
    - The current path is the default on Windows 7 x64 for PostgreSQL 9.6.


## Setup
Double-click the following batch scripts in order to step through the setup process:

- `demo1_prepare_cluster.bat`: creates a new database cluster under "postgres/data".
- `demo2_load_juno_database.bat`: loads the OpenClinica database for the JUNO study.
- `demo3_build_datamart.bat`: runs the DataMart setup and extracts CSV files described in the Introduction.
- `demo4_export_stata_script_from_psql.bat`: optional step to generate a Stata export script.
    - This can also be generated through Stata with the `snapshot_stata.do` script.

If you have completed these steps and want to start the database cluster without starting over, double-click the script `util_restart.bat`.

Possible next steps:

- Browse the generated database: see the section below "Further Browsing", or
- Execute and browse the Stata export: see the section below "Stata Export", or
- Remove the directory "./postgres/data" to clean up the demo database files.


### Other Files in the Demo Directory
Other files present in the demo directory are:

- `juno.backup`: a "plain" SQL backup of the OpenClinica database for the JUNO study.
    - Uses the SQL backup format so it can be loaded into PostgreSQL versions older than 9.6.
- `ocdm-x64.dsn`: an ".ini" format settings file for ODBC connection settings. 
    - An ODBC connection string may specify the path to a DSN file instead of the connection parameters.
    - `demo4_export_stata_script_from_psql.bat` is an example of the parameters method,
    - `snapshot_stata.do` is an example of the file DSN method.
- `setup_sqldatamart.bat`: the main DataMart installer, configured for this demo.
- `util_copy_juno_to_new_db.bat`: generates an database dump of the DataMart JUNO schema,
- `util_dm_copy_schema_to_tables_for_export.sql` function to convert JUNO matviews to tables for export,
- `util_restart.bat`: (re)starts the database cluster.


[Back to Contents](#contents)


## Further Browsing
To explore the DataMart database, a graphical tool like pgAdmin may be useful. The pgAdmin app is included with the EDB distribution of PostgreSQL. The version included depends on the PostgreSQL version:

- 9.6 has pgAdmin4: `C:\Program Files\PostgreSQL\9.6\pgAdmin 4\bin\pgAdmin4.exe`,
    - This is a relatively new re-write so may have some bugs that need ironing out.
- 9.5 and earlier has pgAdmin3: `C:\Program Files\PostgreSQL\9.5\bin\pgAdmin3.exe`.
    - Available separately at: https://www.postgresql.org/ftp/pgadmin3/release/v1.22.1/win32/

The interface of pgAdmin is similar in both versions. Without replicating the pgAdmin user guide here, you should be able to explore the database by doing the following in pgAdmin:

- Add a new server connection: name=datamart_demo, host=localhost, port=5446, maintenance_db=postgres, user=postgres, password=password.
- Connect to this new server "datamart_demo",
- In the server, connect to the DataMart database named "openclinica_fdw_db",
- In the database, expand the "Schemas" list,
- Expand the schema named "the_juno_diabetes_study",
    - pgAdmin3: expand the "Views" list to see the views and materialized views,
    - pgAdmin4: expand the list of "Views" or "Materialized Views",
- Right-click a view or materialized view, choose "View Data" then "View All Rows",
- Or write a custom SQL query: Tools -> Query Tool -> write SQL -> F5 to run.


## Stata Export
To export to Stata, the process is:

- Copy the template script `snapshot_stata.do`,
- Update the variable "filter_study_name_schema" to select the study to export,
- If necessary, update the output directory and ODBC connection details.

When run, this script executes a function in DataMart (public.dm_snapshot_code_stata), which returns the Stata commands necessary to load, label and save the study data. This script can be immediately executed (per the last line in `snapshot_stata.do`), or saved for further modification. Because DataMart prepares the script, it's possible to obtain this script using any other program - for example the above demo uses the command line tool psql.

To provide an example of when it might be necessary to modify the generated Stata script, in this case the designers of the JUNO study have used item names which are longer than the 32 character maximum for Stata. This causes the script to stop during processing of the item group named "IG_DIABE_DIABETES", the commands for which are on lines 151 to 171.

When Stata encounters a variable whose name is too long, the name is replaced with "varXX", where "XX" is the variable's position in the dataset. To resolve this problem, we must modify the commands for the variables with names that are too long, so that they reference variable names Stata has chosen. 

The renamed variables can be found in Stata's "Variables" window, filtering for "var". Four variables with the name "_label" were renamed as well, but these are not important as they don't have variable labelling commands provided, and are a string column with the value label of an adjacent coded variable with the same name. The variables of interest are then:

- other_diabetic_neuropathy_mhoccur: renamed to var30
- other_diabetic_neuropathy_mhstdat: renamed to var32
- severe_hypoglycemic_reaction_mhoccur: renamed to var36
- severe_hypoglycemic_reaction_mhstdat: renamed to var38

Another way to get this information is to use the following Stata commands:

```
ds var*, not(varl *_label)
describe `r(varlist)', n
````

In the Stata script, find the variable labelling commands "lab var ..." and replace the actual variable name with the name Stata assigned. Once these changes are complete, execute the script, and it should finish the export without error - although you may need to remove ".dta" files from the last run. 

These modifications have already been applied in the file `snapshot_stata_code_modified.do` - to use it you'll need to update the paths at the top of the file to suit your environment.

Since the variable positions in the item group datasets don't change unless the study CRF definitions change, this modified script can be used repeatedly, further enhanced, or adapted for automated reports. 


[Back to Contents](#contents)
