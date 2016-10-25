# Demo Basic Using Juno

## Contents
- [Introduction](#introduction)
- [Preparation](#preparation)
- [Installation](#installation)
- [Results](#result)
- [Stata Export Example](#stata-export-example)


## Introduction
This folder provides resources for taking Community DataMart for a test drive. Here we use a demo database containing a test study called "JUNO". The end result is what you could expect to get after following the "Basic" installation instructions. 

We'll use a throwaway database cluster folder, so you won't have anything to clean up from your PostgreSQL installation afterwards. During setup, a folder named "postgres\data" will be created, about 100MB in size, which can be safely deleted after you're completely finished with the demonstration.


## Preparation
These instructions and scripts assume you're using Windows 7 or equivalent. For Linux or Mac users, see the below sub-section for notes.

Before you start, complete the following configurations.

- Install PostgreSQL 9.6 on your machine. 9.3 or later should be fine but latest is best.
- Update "postgres/pg_env.bat". If you used the default installation path with 9.6, you'll only need to update the PGDATA path, which depends on where you saved the DataMart repository.
- Update "setup_sqldatamart.bat". In particular:
    - PostgreSQL port number, if you changed it in "postgres/pg_env.bat",
    - Path to the DataMart repository root, i.e. where the "LICENSE" file is.
    - The postgres superuser name and password you want to use (currently "postgres" and "password", respectively)


### Linux and Mac Notes
For Linux or Mac users, there are some minor changes required to adapt the batch scripts used here to their bash equivalents. For example:

- "SET" statement keywords to "EXPORT", 
- Chevron (caret) line continuation character to a backslash, i.e.: ^ to \\
- Double quoted variable expansions, i.e.: "%psql%" to \\"$psql\\"
- Syntax for recursing through a directory for SQL files.
- There's a good guide here: http://tldp.org/LDP/abs/html/dosbatch.html


## Installation
Double-click the "demo_build_database.bat" file.


## Results
A command prompt will open, the database will be built, and the PostgreSQL server will keep running as long as that command prompt stays open. When you're finished with it you can just close the prompt. 

If you want to start it up again later, double-click the "demo_start_previously_created.bat" file instead - as before, a prompt will open which runs the server for as long as it stays open.

Once the database is built, some example data files are written out as CSV to the demo directory for you to browse (or use the copy saved in  "basic_setup_using_juno.7z"):

- "juno_matviews.csv": a list of all the materialized views that were created.
- "subjects_listing.csv": a list of all the subjects in the JUNO study.
- "item_group_example.csv": an example item group table, "IG_EATIN_HABITS".


### Further Browsing
If all this has got you interested, you could further explore the report database using an app like pgAdmin, which comes with PostgreSQL distributions for Windows.

If using PostgreSQL 9.6, pgAdmin4 should be found here:

```C:\Program Files\PostgreSQL\9.6\pgAdmin 4\bin\pgAdmin4.exe```

If using PostgreSQL 9.5 or earlier, pgAdmin3 should be found here:

```C:\Program Files\PostgreSQL\9.4\bin\pgAdmin3.exe```

The interface of pgAdmin is similar in both versions. Without replicating the pgAdmin user guide here, you should be able to explore the database by doing the following things by double-clicking in pgAdmin:

- Expand the "Servers" list,
- Connect to "PostgreSQL 9.6 (localhost:5446)" (enter the password when prompted),
- Connect to the database named "openclinica_fdw_db",
- Expand the "Schemas" list,
- Expand the schema named "the_juno_diabetes_study",
- pgAdmin3: expand the "Views" list to see the views and materialized views,
- pgAdmin4: expand the list of "Views" or "Materialized Views",
- Right-click a view or materialized view, choose "View Data" then "View All Rows",
- Or write a custom SQL query by finding "Tools" in the top left menu area, then clicking "Query Tool".


## Stata Export Example
To demonstrate the client tools, a copy of the Stata script for generating an export of the study to Stata ".DTA" files is included with example parameter values. 

The idea is that for each study, a user makes a copy of the "snapshot_stata.do" script, inserts their parameter values as instructed in the script, and runs it in Stata to generate another (much longer) export script that contains the commands necessary to export everything an analyst might dream of: study metadata tables, the item group data, and in-line commands for applying variable and value labelling commands to the item group data.

The export script can also be used as a shortcut for building custom reports in Stata since it contains all the data loading and labelling commands.

Note that study management related data sets like discrepancy notes, SDV history and such are not included in the Stata export, since these are typically irrelevant to analysts. They can still be accessed of course, but exporting them just to be ignored (or worse, manually deleted every time) would be a waste of effort. The VBA script for Access does link these extra data sets up by default though, since it is often the tool of choice for project coordinators and data managers.


### Oh No
It happens that JUNO is a good example of the difficulties in accomodating multiple different systems, and the value of a consistent and brief naming convention. For the majority of item groups in JUNO, there is no problem. However, one item group has some items whose names are longer than what Stata can handle, which is 32 characters maximum. The following items from the item group "IG_DIABE_DIABETES" are the culprits:

- other_diabetic_neuropathy_mhoccur
- other_diabetic_neuropathy_mhstdat
- severe_hypoglycemic_reaction_mhoccur
- severe_hypoglycemic_reaction_mhstdat

What Stata does to deal with this problem is to assign these variables new, very short names based on their position in the dataset: "var30", "var32", "var36" and "var38" respectively. There are also some "_label" variables whose names are too long for Stata, but these don't matter so much because "_label" columns do not have Stata variable label commands generated for them; the adjacent non-"_label" column with the item coded value already has this.

The solution is to edit the generated export script and change the variable labelling commands so that they reference these Stata-issued names instead of the originals. To go even further, straight after the "odbc load" command for this item group, we could insert some "rename" commands to change these very short names to something more meaningful, and update the variable label commands accordingly.

It's somewhat annoying, but on the bright side, since these names are based on column positions, this solution is stable and the modified export can be re-used as-is until / unless a new CRF version inserts additional items to the item group.

The necessary edits have already been applied to a copy of the export script in "stata_output/snapshot_stata_code_modified.do", at lines 153, 154, 167 and 168. This modified script can be run to generate the ".DTA" export, or if you don't have Stata, the generated files are in the archive "stata_output.7z". Many other statistical software packages have utilities to import Stata format files if you'd like to view them.

At the point where extracts are being done it's a bit late, but establishing a study design conventions document and training users in that can help avoid these kind of interoperability issues for systems frequently used at an institution.