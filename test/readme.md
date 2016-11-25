# Tests

## Introduction
This document describes how to setup the test environment for development.

This process can also be used to check if your own OpenClinica database will build successfully, see the section [Test a Database](#test-a-database).

The repository includes a `.idea` directory. This contains settings for Intellij IDEA, including run configurations the test build and test run steps described below.


## Environment Setup
To prepare the test environment:

- Install PostgreSQL 9.6+
- Check that the variables in `pg_env.bat` are OK:
    - `pg_install_path`: currently the default install path for Windows,
    - `PGPORT`: the port that the test database will run on.


## Test Build
To run the test build:

- Open a command prompt in the test directory.
- Run `call setup_test_environment.bat`.
    - Creates and starts a new test database cluster,
    - Loads the fixture database specified in the variable `fixture_database`,
- Run `call setup_sqldatamart.bat`. 
    - Runs the build process.
    - For subsequent re-builds, repeat this command.

The test server log file is stored at `.\postgres_data\test_log.txt`. This log file contains all statements issued to the database server, which is useful for debugging.

The test database server will continue running as long as the command prompt stays open. To shutdown the server, run `call stop_test_server.bat`.


## Running Tests
Complete the following:

- Run a test build.
- Install Python 3.x (Older Python may still work, but use 3.5 or better).
- Open command prompt in test folder.
- Create virtual environment: `C:\Python35\python -m venv venv`
- Activate virtual environment: `call venv\Scripts\activate.bat`
- Install the requirements: `pip install -r requirements.txt`
- Run tests: `python -m unittest`.


## Test a Database
To test a database:
 
- Create a database backup file using pgAdmin or pg_dump,
- Save the backup file in the `fixtures` folder, named like `study_name.backup`, 
- Edit `setup_test_environment.bat`, and change the variable `fixture_database` to match the `study_name`.
- Run a fresh test build.
