# SAS Clients


## Summary
- [Ad-hoc](#ad-hoc)
- [Study Snapshots](#study-snapshots)


## Ad-hoc
The following command creates an ODBC connection to OCDM with a creates a 
LIBREF to *myStudyName* (insert File DSN reference string, or ODBC connection 
string):

```sas
LIBNAME myStudyNameLibName ODBC SCHEMA=myStudyNameSchemaName
NOPROMPT="fileDSN reference string, or ODBC connection string";
RUN;
```

The *SCHEMA* instruction informs SAS that references to objects in that 
library refer to objects in the specified schema, so that only the view name 
needs to be specified when writing SET statements (as shown in the following 
example).

The created library may only show views in the myStudyNameSchemaName schema, 
but not materialized views. These can still be accessed by name, for example 
the following command copies the contents of the *subjects* materialized view 
to the *work* library:

```sas
DATA work.subjects; SET myStudyNameLibName.subjects; RUN;
```


## Study Snapshots
