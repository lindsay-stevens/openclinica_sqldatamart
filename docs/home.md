# Welcome
Welcome to the openclinica_sqldatamart documentation!


# Summary
- [Introduction](#introduction)
- [Output](#output)
- [Setup](#setup)
- [Clients](#clients)
- [Reference](#reference)


# Introduction
This project is a collection of PostgreSQL SQL scripts and PL/SQL functions 
that build a reporting database from an OpenClinica database.

The scripts use the OpenClinica metadata to construct a database which can be 
accessed by clients which require tabulated data.

The aim is for the system to take care of the repetitive parts of setting up 
reports and getting data for analysis, so you can go straight to implementing 
the study-specific parts.


# Output
- A database
- A schema with foreign tables to the OpenClinica objects.
- A schema with the core queries.
- A schema for each study in your OpenClinica instance.
- In each study schema:
  + A copy of the core queries filtered for that study.
  + Queries for each item group with items as columns.
- Group role for each study with select access to that study.
- Login role for each study level user in OpenClinica.
  + Group roles granted to Login roles accordingly.


# Setup
In general, the setup involves the following steps.
- Install a secondary postgres cluster (9.3+) to connect to the existing 
  cluster which has OpenClinica database. Same machine or different one.
- Do some configuration to both clusters to allow them to connect.
- Put your settings in a setup script and run it to create the report database.
- Set up a scheduled task to run maintenance scripts, which keep study schemas,
  study data and roles up to date.
  + e.g. using pgAgent (Linux/Windows), schtask (Windows) or cron (Linux).

There are instructions / tips in this wiki for:
- Basic setup.
- Advanced setup.
  + Setting up secure connections between servers and server to client.
  + Setting up client authentication against Active Directory with SSPI.
  + Performance and logging configurations.
- Maintenance setup.


# Clients
There are helper scripts for some client types:
- Snapshot of study data with SAS.
- Snapshot of study data with Stata.
- Creating pass-through queries in Microsoft Access


# Reference
The scripts are organised into the following components:
- openclinica_fdw: Creating the foriegn tables and matviews.
- dm: Creating the core queries.
- study: Creating the study schema objects.
- utils: Creating roles, refreshing matviews, snapshot helper code.
