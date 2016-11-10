# Tests

## Introduction
At the moment this is mostly a relatively rudimentary test at the level of "did I substantially break it" rather than a suite of specific pass/fail conditions. 

The test process will do the following:
 
- Create / replace a throwaway database cluster under ".\postgres_data",
- Load the JUNO demo OpenClinica database,
- Run the DataMart build script,
- Dump the schema and data generated for the JUNO study.

Once this is complete, the JUNO dump file under ".\test_output" can be diffed against a known good copy under ".\fixtures" to investigate brokenness.


## Running the Test Build

To run test build:

- Install PostgreSQL 9.6.
    - 9.3+ might be OK, but latest is best.
- In "pg_env.bat", check that the variable "pg_install_path" is correct.
    - Currently set to the default install path for 9.6 on Windows 7 x64.
- Run the script `test_build.bat`.

A copious amount of information will be shown on the console window. To run this more quietly and send the information to a log file, run the script `test_build_to_log.bat` instead.:

The test_build script also runs the PostgreSQL server process, so the window will stay open after the build is completed. The window can be closed if no further investigation or browsing is to be done.

There is also the PostgreSQL log file under ".\postgres_data\test_log.txt" to help with debugging.


## Running Tests
There are some tests under "test_cases". To run these:

- Run the test build, leaving the console open so the server is still running,
- Run the script `run_test_cases.bat`.

If you have kdiff3 installed, the script `kdiff_datamart_output.bat` will launch kdiff to compare the new dump file against a known good one.
