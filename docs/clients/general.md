# Clients General Setup


## Summary
- [Connection Protocols](#connection-protocols)
  + [ODBC](#odbc)
    - [The psqlODBC Driver](#the-psqlodbc-driver)
    - [Connection Definitions](#connection-definitions)
      + [Strings](#strings)
      + [FileDSNs](#filedsns)
- [Certificate Verification](#certificate-verification)
- [DNS Lookup Issues](#dns-lookup-issues)


## Connection Protocols
Many applications can use ODBC to communicate with postgres, such as MS Office, 
LibreOffice, Stata, SAS, etc. 

LibreOffice includes the necessary ODBC and JDBC drivers; however most other 
applications will require a driver to be installed, in this case psqlODBC.

If you plan to access data using a programming language, usually there is a 
package for facilitating that. For example Python has psycopg2, and Java has 
JDBC.


### ODBC


#### The psqlODBC Driver
If you plan to use ODBC to connect, install the psqlODBC driver. The installer 
should install both 32bit (*PostgreSQL Unicode*) and 64bit 
(*PostgreSQL Unicode(x64)*) drivers on a 64bit system, or just 32bit on a 
32bit system. 

The release cycle for psqlODBC generally follows that of postgres which is 
approximately annually, so clients should update their version accordingly.

When creating a connection, the driver bits should only be relevant if the 
application is 32bit, as a 32bit application will not be able to use the 
64bit driver. 64bit applications are usually able to use either the 64bit or 
32bit driver.

- Install using the windows installer from postgresql.org.


#### Connection Definitions
Most applications that can use ODBC will accept and ODBC string to define the 
connection parameters. FileDSNs can provide the same parameters, but have the 
advantage of being able to be centrally managed.

In the following examples, to use the 64bit driver, use the driver name 
"PostgreSQL Unicode(x64)"; for 32bit, use the driver name "PostgreSQL Unicode".

##### Strings
ODBC connection strings use the following syntax (adjust each parameter as 
appropriate):

```
"DRIVER={PostgreSQL Unicode(x64)};DATABASE=openclinica_fdw_db;SERVER=myOCDM_FQDN;PORT=myOCDM_port;SSLmode=verify-full;TextAsLongVarchar=0;UseDeclareFetch=0"
```

To explain these settings:
- DRIVER: how to connect. In this case, using the PostgreSQL ODBC driver.
- DATABASE: the name of the database to connect to.
- SERVER: the name of the machine where OCDM is located.
- PORT: the TCP port that OCDM is listening on.
- SSLmode=verify-full: always verify the certificate presented by OCDM.
- TextAsLongVarchar=0: don't interpret PostgreSQL TEXT columns in Access as MEMO.
- UseDeclareFetch=0: don't try to speed up data retrieval by fetching 100 rows 
  at a time. If using SSPI authentication, this will cause a new connection to 
  be opened for every 100 rows in a query, which can be a problem if the 
  server setting max_connections is set low.


#### FileDSNs
FileDSNs use the following syntax (adjust each parameter as appropriate):

- Create a file named *ocdm-x64.dsn* that contains the following text:

```
[ODBC]
DATABASE=openclinica_fdw_db
DRIVER=PostgreSQL Unicode(x64)
SERVER=myOCDM_FQDN
PORT=myOCDM_Port
SSLmode=verify-full
TextAsLongVarchar=0
UseDeclareFetch=0
```

- Do the same for the 32 bit driver, create a file named *ocdm-x86.dsn*, with the following difference:

```
DRIVER=PostgreSQL Unicode
```

- Use a reference to the appropriate FileDSN in ODBC connection string as follows:

```
"FILEDSN=\\path\to\ocdm-x64.dsn"
```


## Certificate Verification
If the advanced setup was completed, clients will be required to use an 
encrypted connection. Clients should verify the authenticity of the certificate 
provided by the OCDM postgres server.

In order to verify a cerificate, the issuer chain is required. If using a 
popular certificate authority, these root CA certificates are sometimes 
distributed as part of a "CABUNDLE". 

All that is really required is a copy of the issuer chain for the OCDM cert. 
This was prepared as part of the advanced setup steps.

- Copy the OCDM *root.crt* to the following directory, substituting 
*ClientUserName* for the client user name:

```
C:\Users\ClientUserName\AppData\Roaming\postgresql\root.crt
```


### DNS Lookup Issues
This step may not be required in your environment. MS Access seems to be 
sensitive to DNS lookup timeout when initiating an ODBC connection. A 
workaround is to provide the machine with the IP matching the OCDM FQDN by 
adding a *hosts* file record. 

The suitability of this workaround depends on the stability of the IP address - 
if it static then it should not need to be updated after being created once 
per machine.

The IP address and server names are stable so this should only need to be done 
once per user. The hosts file is usually in the following directory:

```
C:\Windows\System32\drivers\etc\hosts
```

- Enter the IP / hostname mapping in the following format.

```
myOCDM_IP    myOCDM_FQDN
```