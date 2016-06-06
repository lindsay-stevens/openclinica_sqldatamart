# Naming Limitations


## Introduction
OpenClinica has documented naming conventions and limitations. In some cases 
these are directly compatible with database systems and statistical packages,
in other cases there is some manipulation required to obtain a valid identifier. 

The following sections summarise the naming rules for OpenClinica and a variety 
of systems, and determines a lowest common denominator between them all. The 
naming strategy favours short identifiers and if needed falls back to appending 
database sequence ids to derive a unique but predictable name.

This strategy has not yet been implemented in datamart, see the "output.md" 
documentation file for the current approach.


## Overview
Implementation details are described at the bottom of this document.

The new approach would produce the similar results to the current one as long as:

- Item names are unique within an item group within the first 15 characters,
- Item Group names are unique within a study within the first 20 characters.

Key differences are:

- No longer using separate "ig_" and "av_ig_" views, since there is even more 
  limited useful information in 32 characters (vs. current 45) available for 
  appending to the item names, and largely just increases the amount of typing 
  involved in writing queries and reports.
- Multi-select items are identified by the order they appear in the response 
  set as well as the CRF version ID. This is to cope with studies where the 
  coded value contains invalid characters, or is very long. It also deals with 
  the possibility that two different choices have the same position in 
  different CRF versions.
- Label columns are denoted by a shorted suffix "_l", rather than "_label", so 
  as to use less of the available 32 characters.
  
These naming conventions should be able to cope with the following parameters 
for an instance of OpenClinica before running in to problems:

- Up to 999,999 records across all studies for items, item groups, response set
  members, and CRF versions, respectively.
- Up to 22,770 columns in a single item group definition
  + Each single-select or radio has a value and label column,
  + Each multi-select or checkbox has a value and label column for each choice.
- Up to 10^28 response sets.


## OpenClinica 3.11
https://docs.openclinica.com/3.1/technical-documents/openclinica-and-cdisc-odm-specifications/cdisc-odm-representation-openclin-6

- non-unique names are appended an underscore and random 3 digits
- study events: begin with "SE_", up to 28 characters, only a-Z0-9
- crf: begin with "F_", up to 12 characters, a-Z0-9
- crf version: begin with crf oid, then up to 10 characters
- item group: begin with "IG_" then first 5 of CRF name, then first 32 
  alphanumeric characters in item group name (total max oid 40).
- item: begin with "I_" then first 5 of CRF name, then first 26 alphanumeric 
  characters in item label (total max oid 33)
- measurement unit: begin with "MU_" then first 37 of unit name
- rule: alphanumeric, all caps, 40 characters, unique within study.
- study: begin with "S" then first 8 alphanumeric in study unique protocol id
- site: begin with "S" then first 8 alphanumeric in study unique protocol id
- study subject: "SS_" then all alphanumeric in study subject id. unique within 
  the openclinica instance.


## Access 2007, 2010
https://support.office.com/en-us/article/Guidelines-for-naming-fields-controls-and-objects-3c5d8ebd-08b5-472a-ae57-c3632910068b
https://support.office.com/en-us/article/Access-2010-specifications-1e521481-7f9a-46f7-8ed9-ea9dff1fa854

- 64 characters long
- not allowed: !`[]
- can't begin with a space
- can't include control characters (ASCII 0 to 31)
- table/view/procedure names can't have double quote "
- sql keywords not allowed
- case insensitive
- max. 255 fields per table, max 2GB for whole database.


## Excel 2010
https://support.office.com/en-us/article/Excel-specifications-and-limits-1672b34d-7043-467e-8e27-269d656771c3

- max. 32,767 characters per cell
- max. 1,048,576 rows and 16,384 columns
- sheet count limited by available memory.


## Postgres 9.5
https://www.postgresql.org/docs/current/static/sql-syntax-lexical.html
https://www.postgresql.org/about/

- 63 characters long
- A-z0-9 or underscores, non-latin characters, dollar signs allowed
- can't begin with a $ or number
- quoted identifiers can have any character except ASCII 0
- sql keywords not allowed
- case insensitive (unless quoted identifier)
- max. row size 1.6TB, between 250 to 1600 columns depending on data type.
- max. table size 32TB.


## SAS 9.4
http://support.sas.com/documentation/cdl/en/lrcon/68089/HTML/default/p18cdcs4v5wd2dn1q0x296d3qek6.htm
http://www.sascommunity.org/wiki/Long_labels_in_PROC_FORMAT
http://support.sas.com/documentation/cdl/en/hostwin/63285/HTML/default/viewer.htm#numvar.htm

- 8 to 32 characters, depending on object type
- 8: engines, filerefs, librefs, passwords
- 16: call routines, functions, procedure names
- 28: generation data sets
- 30: character informats
- 31: character formats, numeric informats
- 32: arrays, catalogs, components, data step statement labels, data step 
  variables, data step windows, numeric formats, macro variables, macro 
  windows, macros, SAS library members, scl variables
- 256: data step variable labels
- V7 rules: 32 character variable & dataset names
- must being with A-z or underscores
- can contain a-Z0-9 or underscore
- not a SAS name for a special variable or function
- variable labels up to 256 characters
- can label integers, ranges, and strings.
- value labels may be up to 32,767 but only 262 characters at a time, can 
  get to the limit by putting adjacent quoted strings in the value definition.
- case insensitive
- max. about 1.35 million variables per data set.


## Stata 14
http://www.stata.com/manuals14/u11.pdf
http://www.stata.com/manuals14/rlimits.pdf

- 32 characters long
- A-z0-9 or underscore
- local macro names limited to 31 characters
- not a reserved word (special variable names, data type names, functions)
- must begin with a letter or underscore (macros may start with a digit)
- advised to avoid beginning with underscore as these denote reserved variables
- variable labels up to 80 characters
- can attach 1 to n notes to a variable, tested up to 30,000 characters accepted
- value label definitions up to 32,000 characters combined for one label set
- dataset labels up to 80 characters
- can label integers only.
- case insensitive
- max. 2047 variables per data set (IC version, 32767 for MP and SE)
- max. 65536 codes per value label definition.


## R 3.3.0
https://stat.ethz.ch/R-manual/R-devel/library/base/html/make.names.html
https://stat.ethz.ch/pipermail/r-help/2004-June/052396.html

- may contain a-Z0-9, dot or underscore
- may begin with a letter, or a dot but not dot then a number (.2 is not valid)
- not a reserved word (keywords, bool/null)
- allowed letters depend on locale (utf-8?)
- "x" is prepended to otherwise invalid names
- each invalid character is replaced with a dot
- names matching R keywords have a dot prepended
- variable labels: not built in, can use data.frame to store them or use 
  a package (which has similar name rules to variables).
- data set size limited to 2^31-1 items, otherwise limited by available RAM.


## Lowest Common Denominator Naming Strategy
In all scenarios where a name is manipulated, the metadata should provide a 
column with the original name as well as the modified name, so that the 
modified names can still be used to look up metadata.

- 32 character variables and data set names
- character set: [a-Z0-9_]
- name must begin with a letter
- case insensitive
- no names resembling a programmatic keyword or standard column name.
- variable labels: target system dependent.
    + Access, R: refer to labels in metadata data sets
    + Stata: first 80 characters in variable label, remainder dropped
    + SAS: first 256 characters in variable label, remainder dropped
- value labels: target system dependent.
    + Access, R: refer to labels in paired column.
    + Stata: value labels for integers only. Label name "L" then 
      response_set_id, then "_".
    + SAS: value labels for integers and strings. Label name "L" then 
      response_set_id, then "_". Starting with "$" if string label.
- item names: OpenClinica max is 33 characters.
    + The oid prefix is not important as items are already namespaced in an 
      item group, e.g. by virtue of the table they are in.
    + get all item_oids and remove "I_CRFID_" prefix, then take the first 
      15 characters. If the string does not start with a letter, prefix it with 
      the letter "x". Check if these strings are unique within each item group, 
      including all CRF versions and standard column names (e.g. event_name).
    + if unique, use this <=16 character name for the item (15 +- "x").
    + if not unique, keep first 9 characters then append last 6 digits of 
      item_id: _999999 (7) -> 16 characters max.
    + for multi-choice items, append last 6 of choice order then crf_id
      (14) -> 30 characters max.
    + for label columns, append "_l" to the corresponding item name -> 32 
      characters max.
- item groups: OpenClinica max is 40 characters.
    + The oid prefix is important as it namespaces the item groups within the 
      study schema, and indicates which CRF they belong to.
    + Maximum in Access is 255 columns per table, reserving 25 columns for 
      standard metadata (currently 13 in use), leaves 230 per data set.
    + get all item_group_oids, keeping the "IG_CRFID_" prefix, and take the 
      first 29 characters. For item groups with more than 230 items, generate 
      additional names by appending "_01" and so on for each multiple of 230.
      Check if these names are unique within the study.
    + if unique, use this <=32 character name for the item group (29 +- 3 for
      multiple of 230 number).
    + if not, keep first 22, then append last 6 digits of item_group_id: 
      _999999 (7), then append the 230x multiple -> 32 characters max.
    + The 230x multiple numbering has up to 99 values and therefore supports 
      item groups with up to 22,770 items, which is about 35% of the maximum 
      number of rows in an Excel 2003 XLS spreadsheet (65,536).
- reserved words:
    + as part of the unique checks for items and item groups, check names 
      against SQL-92, SQL:2008 and SQL:2011 keywords, as well as names reserved 
      in SAS and Stata. Matching one of these has the same consequence as a non 
      unique name, e.g. truncate then append relevant database sequence id.


## Bonus Round: Data Type Inspection
It is apparently possible to define in OpenClinica an otherwise invalid item as 
follows:

- RESPONSE_TYPE: single-select
- RESPONSE_OPTIONS: No,Yes,Maybe
- RESPONSE_VALUES: 0,1,2
- DATA_TYPE: DATE

This will cause the datamart build process to fail as the values 0, 1 and 2 
can't be cast to the DATE type in Postgres. A possible solution to handle this 
might be to define a custom CAST function, which returns DATE if all values 
can be cast to DATE, or on exception, return TEXT. If this works then an 
additional round to try DATE then INT then TEXT might work. 

This inspection would only be required if the item has a response set defined, 
but would be required for all items with a response set, which may be time-
consuming.
