# Stata Clients


## Summary
- [Ad-hoc](#ad-hoc)
- [Study Snapshots](#study-snapshots)


## Ad-hoc
The following command creates an ODBC connection to OCDM and copies the 
contents of the *subjects* materialized view for *myStudyName* (insert File 
DSN reference string, or ODBC connection string):

```stata
odbc load, table("myStudyNameSchemaName.subjects") noquote connectionstring("fileDSN reference string, or ODBC connection string")
```


## Study Snapshots