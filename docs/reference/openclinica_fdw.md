# openclinica_fdw

## Overview
The scripts described in this section are responsible for the creation of 
objects in the openclinica_fdw schema. 

The scripts are executed in the following order.

- [dm_create_ft_catalog](#dm_create_ft_catalog)
- [dm_create_ft_openclinica](#dm_create_ft_openclinica)
- [dm_create_ft_openclinica_matviews](#dm_create_ft_openclinica_matviews)
- [dm_create_ft_openclinica_matview_indexes](#dm_create_ft_openclinica_matview_indexes)

## Scripts

### dm_create_ft_catalog

#### Purpose
Create foreign tables for pg catalog tables for looking up other table defs.

#### Description
Creates the following foreign tables in the openclinica_fdw schema.

- pg_attribute
- pg_class
- pg_namespace
- pg_indexes

These objects are used for looking up the definition of the OpenClinica objects
in the foreign database. These pg catalog table definitions rarely change, so it
is a reasonably reliable way to get the object definitions without needing to
specify the OpenClinica object definitions in a similarly verbose way.

#### Parameters
None.

#### Returns
Void.

### dm_create_ft_openclinica

#### Purpose
Create foreign tables for OpenClinica objects for retrieving data.

#### Description
Creates a foreign table in the openclinica_fdw schema for each table or view in
the specified foreign OpenClinica schema.

For each object in the foreign pg_class, inspect the foreign pg_attribute to get
the column names and column types and aggregate this into a string. 

Insert the column definitions string and the object name into a 
*CREATE FOREIGN TABLE* statement.

#### Parameters
- foreign_openclinica_schema_name
  - description: name of foreign schema which has the OpenClinica objects
  - type: string
  - default: public

#### Returns
Void.

### dm_create_ft_openclinica_matviews

#### Purpose
Create materialized views for OpenClinica objects to locally cache the data.

#### Description
Creates a materialized view in the openclinica_fdw schema for each foreign table
in the openclinica_fdw schema.

For each foreign table object in pg_class in the openclinica_fdw schema, get the
object name.

Insert the object name into a *CREATE MATERIALIZED VIEW* statement.

#### Parameters
None.

#### Returns
Void.

### dm_create_ft_openclinica_matview_indexes

#### Purpose
Create indexes on the OpenClinica materialized views for query performance.

#### Description
Creates an index on each materialized view in the openclinica_fdw schema for
each index that exists for the corresponding foreign OpenClinica object.

For each index in the foreign pg_indexes, get the index definition and index 
name. The index definition is a *CREATE INDEX* statement.

In the index definition, replace the string referring to the original foreign
schema with the new openclinica_fdw schema.

#### Parameters
- foreign_openclinica_schema_name
  - description: name of foreign schema which has the OpenClinica objects
  - type: string
  - default: public

####
Void.