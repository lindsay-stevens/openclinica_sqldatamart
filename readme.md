# OpenClinica Community DataMart


## Introduction
This is community developed project to enable users to create powerful and streamlined queries and reports. By connecting directly to the OpenClinica backend database, all information stored by the application can be leveraged for analysis and study management tools.

The documentation describes two kinds of deployment scenarios:

- Basic: for one-off data dumps or single-user reporting environments,
- Advanced: for establishing a secure, high-performance, multi-user environment.

Client integration tools are also included:

- A VBA script to generate MS Access pass-thru queries for all study views,
- A Stata script for generating data export code, with variable and value labels,
    - An extension of the above to generate per-site Excel datasets for close-out,
- A SAS script for generating data export code.

For additional information and installation instructions, please refer to the [docs](docs) directory.


## Demo
If you want to try out the basic deployment on your local machine, to see what is involved and what sort of data is available, please refer to the instructions filed under [docs/demo/basic_setup_using_juno](docs/demo/basic_setup_using_juno). 

This demo uses the JUNO test database to build Community DataMart and demonstrate the client tools using the Stata export script as an example. The JUNO database is currently deployed in the demonstration instance for OpenClinica, which is managed by OpenClinica LLC and is accessible at: https://demo.eclinicalhosting.com.
