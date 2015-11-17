# Microsoft Access


## Summary
- [Ad-hoc](#ad-hoc)
- [Study Snapshots](#study-snapshots)


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
