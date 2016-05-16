# Microsoft Access


## Summary
- [Pass-Thru Query Generator](#pass-thru-query-generator)
- [Ad-hoc](#ad-hoc)
- [Study Snapshots](#study-snapshots)


## Pass-Thru Query Generator
Access can be used as a client for writing ad-hoc queries, preparing reports, 
or integrating with other study management data. In order to connect, an Access 
query type called "pass-thru" is used, which sends a request for data to the 
OCDM server via ODBC (see the clients->general documentation for ODBC information).

There are many standard queries for each study, e.g. the list of subjects, 
subject groups, metadata, etc; as well as the item group tables. In order to 
simplify the process of creating pass-thru queries for all these tables, a 
Visual Basic for Applications (VBA) script has been prepared, which will 
generate pass-thru queries for all materialized views in a specified schema.

The VBA script is at "clients/access_make_passthru_queries.bas". To use it, 
complete the following steps.

- Create a new Access database (or open an existing one).
- Open the Visual Basic IDE by clicking on the "Database Tools" tab, and then 
  clicking on the "Visual Basic" button.
- Import the script by click on "File", then "Import File...", then selecting 
  the script from the file system.
- Run the script by clicking on the "Immediate" window, then typing the 
  following command: ```?make_passthru_queries("mystudy","ODBC string")```, 
  then press Enter.
    + Replace "mystudy" with the study schema name, 
    + Replace "ODBC string" with the connection string to use (or FILEDSN).
    + If the Immediate window is not shown, click on "View", then "Immediate 
      Window".
- Close the VBA IDE and check that the pass-thru queries connect successfully.


### Getting the "av_" Views
The script by default will generate pass-thru queries for all the materialized 
views, which includes the standard tables as well as long-named item group 
tables. If the short-named "av_" views are needed, the script can be modified 
by replacing lines 32/33 as follows:

```
object_sql = "SELECT pg_views.viewname AS objectname FROM pg_views " _
        & "WHERE pg_views.schemaname=" & Chr(39) & study_schema_name & Chr(39)
```

Once this replacement is done, re-run the script as described above.


## Ad-hoc
MS Office ODBC connection strings require a prefix of "ODBC;". Generally, it is 
easier to create the connection by browsing to the FileDSN, particularly for 
MS Excel.

In MS Access, pass-through queries accept an ODBC connection string in the 
property sheet. Alternatively, select the fileDSN location and Access will 
insert the equivalent ODBC connection string for the pass-through query. Linked 
tables can also be created by selecting the fileDSN location.

When creating local queries based on pass-through queries and joining queries, 
performance can be very slow. For example a query that executes on the server 
in ~20ms can take ~20 seconds to run in Access. In this situation, execution 
time was improved to ~3 seconds by changing Access database settings. 

Close all database objects, then go to Access Options -> Current Database -> 
Name AutoCorrect Options. Ensure that all autocorrect options are unchecked 
(Track Name, Perform, Log name). Another useful setting to change (off by 
default) is underneath; Filter lookup options -> Show list of values in: ODBC 
fields.


## Study Snapshots
While this has not been implemented, the general concept would be to iterate 
through the existing pass-thru queries in the database, and execute table 
copy SQL statements like "SELECT y.* INTO x FROM y" where "x" is the target 
table name (e.g. "snap_ig_conmeds"), and "y" is the source table name (e.g. 
"mystudy.ig_conmeds").
