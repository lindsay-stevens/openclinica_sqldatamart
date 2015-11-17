# Setup


## Dependencies
- PostgreSQL 9.3+
- Win32 OpenSSL v1.0.0o Light (or any other software that can generate a CSR).


## Summary
On OC server:
- [Prepare OC Root Certificate](#prepare-oc-root-certificate)
- [Create an OC Postgres Login Role for OCDM](#create-an-oc-postgres-login-role-for-ocdm)
- [Update the OC postgres Host Based Authentication file](#update-the-oc-postgres-host-based-authentication-file)

On OCDM server:
- [Obtain OCDM Server TLS Certificate](#obtain-ocdm-server-tls-certificate)
- [Prepare OCDM Root Certificate](#prepare-ocdm-root-certificate)
- [Create a Domain Service Account for the OCDM PostgreSQL Services](#create-a-domain-service-account-for-the-ocdm-postgresql-services)
- [Install PostgreSQL on OCDM](#install-postgresql-on-ocdm)
- [Grant Windows Folder Permissions to the Domain Service Account](#grant-windows-folder-permissions-to-the-domain-service-account)
- [Change Postgres Service Accounts](#change-postgres-service-accounts)
- [Update the postgres User Name Map file](#update-the-postgres-user-name-map-file)
- [Update the postgres Global User Configuration file](#update-the-postgres-global-user-configuration-file)
- [Start the postgres service](#start-the-postgres-service)
- [Create postgres OpenClinica Report Database](#create-postgres-openclinica-report-database)
- [Create a postgres Login Role for the Domain Service Account](#create-a-postgres-login-role-for-the-domain-service-account)


## Steps to Complete on OC Server


### Prepare OC Root Certificate
Before opening a secure connection, a client should check the certificate 
presented by the server. One of the checks is that it was issued by a trusted 
certificate. It is common that a CA will issue a certificate using an 
intermediate certificates that is issued by another certificate, and so on, and 
these must also be checked.

Windows maintains a certificate store that has common CA root and intermediate 
certificates, but the libpq library that postgres and psqlODBC use does not 
currently interact with this store. Libpq currently only accepts one file for a 
issuing certificate to use for checking the server certificate. When there are 
intermediate certificates, these must be included in the same file.

- Open the server certificate and inspect the *Certification Path* tab. A copy 
  of all the issuing certificates above the server certificate is required, in 
  PEM format. These should be available on the CA's website.
- Create a file named *root.crt*, and paste in the intermediate certificate(s) 
  and root certificate strings from the issuing certificates, such that the 
  file looks like the following:

```
-----BEGIN CERTIFICATE-----
... intermediate certificate string ...
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
... root certificate string ...
-----END CERTIFICATE-----
```

- Copy this *root.crt* file to the OCDM server, as OCDM will use it when 
  connecting to OC.


### Create an OC Postgres Login Role for OCDM
In order to retrieve data, OCDM needs to be able to connect to OC, which 
requires a login user on the OC postgres server. This server to server 
connection requires password authentication, as it cannot use SSPI.

- Log in to OC postgres as a superuser and run the following commands to create
  a role with the necessary permissions:

```sql
CREATE ROLE "openclinica_select"
    NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE openclinica to openclinica_select;
GRANT USAGE ON SCHEMA public to openclinica_select;
```

- For postgres 9.0+, the run the following command:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;
```

- For postgres <9.0, run the following commands:

```sql
CREATE FUNCTION public.grant_select_on_all_tables_in_schema()
RETURNS VOID AS
$$DECLARE r record;
BEGIN
FOR r IN
    SELECT 'GRANT SELECT ON ' || relname || ' TO openclinica_select;' as grant
    FROM pg_class JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE nspname = 'public' AND relkind IN ('r', 'v')
LOOP
    EXECUTE r.grant;
END LOOP;
END;$$
LANGUAGE plpgsql VOLATILE;
SELECT public.grant_select_on_all_tables_in_schema();
DROP FUNCTION public.grant_select_on_all_tables_in_schema();
```

- Run the following commands to create a login role for the connection:

```sql
CREATE ROLE ocdm_fdw WITH LOGIN ENCRYPTED PASSWORD 'aGoodPassword'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT openclinica_select TO ocdm_fdw;
```


### Update the OC postgres Host Based Authentication file
The Host Based Authentication file (pg_hba.conf) can be found in the postgres
data directory.
- Add a row to allow connections to OC from OCDM (in addition to existing local
  rows, ensure there is no conflict):

```
# TYPE  DATABASE        USER                 ADDRESS                 METHOD
hostssl openclinica     ocdm_fdw             ocdmIPAddress/32         md5
```


## Steps to Complete on OCDM Server


### Obtain OCDM Server TLS Certificate
The following uses OpenSSL for Windows to generate a Certificate Signing Request (CSR).

- Install OpenSSL for Windows (available form Shining Light Productions)
- Open a command prompt and run the following command to generate a CSR 
  (output as *CSR.csr*) and private key (will be output as *server.key*), 
  insert the subject (-subj) parameter details as appropriate:

```
C:\OpenSSL-Win32\bin\openssl.exe req -newkey rsa:4096 -sha512 -nodes -subj "/C=myCountry/ST=myState/L=myLocation/O=myOrg/OU=myOrgUnit/CN=myOCDM_FQDN" -out CSR.csr -keyout server.key
```

- Send the CSR file to a Certificate Authority (CA) and request a certificate. 
- Name the provided certificate file *server.crt*

The secrecy of *server.key* and *server.crt* is very important so do not copy 
them anywhere outside the server.


### Prepare OCDM Root Certificate
As was done for the OC server, a *root.crt* file will be needed for user 
clients connecting to OCDM.

- Create a *root.crt* file using the OCDM *server.crt* certification path.
- Copy this *root.crt* file to each client.


### Create a Domain Service Account for the OCDM PostgreSQL Services
A domain service account is used for the postgres services, which allows the 
use of SSPI authentication for user connections to the database, and allows 
control over the level of permissions associated with the account running these 
services.


### Install PostgreSQL on OCDM
- Use the Windows installer from postgresql.org.
- Choose a good password for the postgres superuser and keep it secret.

There seemed to be a bug in the postgres installation when using double quote 
characters in the password. The *data* directory would fail to be created. Use 
lots of other characters instead.


### Grant Windows Folder Permissions to the Domain Service Account
By default the *data* directory should be created at:

```
C:\Program Files\PostgreSQL\9.3\data 
```

- Put a copy of the OCDM *server.key* and *server.crt*, and the OC *root.crt* 
  in the *data* directory.
- Find the data directory and assign *Full Control* of this directory to the 
  OCDM domain service account. Right-click folder ; Properties ; Security ; 
  Edit ; Add ; enter full domain service account name.


### Change Postgres Service Accounts
- Open services.msc and stop the *postgresql-x64-9.3* service.
- Open the service properties and change Log On to use the domain service 
  account credentials
- Remove the user folder that may have been created for the local postgres user 
  during installation, located at:

```
C:\Users\postgres
```

Do not start either service yet, there are more steps to complete.


### Update the postgres Host Based Authentication file (pg_hba.conf)
The *pg_hba.conf* file is in the postgres data directory, and allows control 
over connections to the database server. The following configuration allows 
local connections for the postgres and domain service account login roles; the 
former by password and the latter by SSPI. Additionally, secure remote 
connections from domain users from the domain user IP range are allowed with 
SSPI.

- Replace the default IPv4 and IPv6 rows with the following:

```
# TYPE  DATABASE        USER                 ADDRESS                 METHOD
host    all             postgres             127.0.0.1/32            md5
host    all             myDomainServiceAccountName             127.0.0.1/32            sspi map=mapsspi include_realm=1 krb_realm=myDomain
hostssl all             all                  domainUserIPRange          sspi map=mapsspi include_realm=1 krb_realm=myDomain
host    all             postgres             ::1/128                 md5
host    all             myDomainServiceAccountName             ::1/128                 sspi map=mapsspi include_realm=1 krb_realm=myDomain
```

SSPI uses the domain credentials of the user to establish authentication, i.e. 
if the user is currently authenticated with the domain, they are trusted to 
connect to the database with their domain user name.


### Update the postgres User Name Map file
The User Name Map file (pg_ident.conf) can be found in the postgres data 
directory, and allows mapping between system and postgres login roles names.

- Add a row to map domain account users to database usernames without the 
  domain part:

```
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
mapsspi       /^(.*)@myDomain$          \1
```

This means that a client connecting with a domain account name of 
*myUser*@*myDomain* is mapped to the postgres login role *myUser*. The case of 
the postgres login role must match the case of the domain account name, e.g. 
myuser=myuser, Myuser=Myuser, MYUSER=MYUSER.


### Update the postgres Global User Configuration file
The Global User Configuration file (postgres.conf) can be found in the postgres 
data directory, and allows control over settings that affect the behaviour and 
performance of the database server.

Settings are disabled by appending a # symbol to the beginning of the line, so 
remove the # symbol for the lines with the settings shown below. The comments 
shown here do not need to be added to the *postgresql.conf* file.

- Locate the rows with settings shown below and update the default values 
  (adjust depending on expected connections and available ram, below is for 
  4GB): 

```
# - Connection Settings -
listen_addresses = '*' # listen to all IP addresses. Controlled further via pg_hba.conf.
port = myOCDM_Port  # port the server listens on, must be unoccupied by other services
max_connections = 10  # set lower limit on the number of connections, mostly for resource consumption

# - Security and Authentication -
ssl = on  # allow use of ssl
ssl_cert_file = 'server.crt'  # name of server cert file in data directory (for OCDM)
ssl_key_file = 'server.key'  # name of server key file in data directory (for OCDM)
ssl_ca_file = 'root.crt' # name of cert trust chain file in data directory (from OC)

# - Memory -
shared_buffers = 1024MB  # raised ram for caching (ram / 4)
temp_buffers = 512MB  # raised ram for temp tables (run/refresh mega queries), (ram / 8)
work_mem = 256MB  # raised ram for sorting (ram / (2 * max_connections))
maintenance_work_mem = 512MB  # raised ram for maintenance operations (ram / 8)

# - Checkpoints -
checkpoint_segments = 128  # raised interval to write a checkpoint, every 128 * 16MB = 2GB
checkpoint_completion_target = 0.75  # raised target to finish checkpoint when next one 75% complete

# - Planner Cost Constants -
effective_cache_size = 3072MB  # raised estimate of available ram for caching (3/4 available ram)

# - Other Planner Options -
default_statistics_target = 1000  # raised limit for statistics entries for query planning

# - Where to Log -
log_destination = 'csvlog' # log to csv format so logs can be analysed more easily 
logging_collector = on  # enable logging
log_filename = 'postgresql-%Y-%m-%d.log'  # log daily file names like postgresql-2015-01-20.log
log_rotation_size = 0  # do not rotate log files based on log file size

# - What to Log -
log_connections = on  # log client connections
log_disconnections = on  # log client disconnections
log_duration = on  # log duration of submitted queries
log_statement = 'all'  # log all submitted statements

# - Lock Management -
max_locks_per_transaction = 10000 # queries can simultaneously affect more than default 64 tables
```


### Start the postgres service
- Open services.msc and start the *postgresql-x64-9.3* service.

Note that restarting or stopping this service typically causes the pgAgent 
service to stop as well (if installed). When (re)starting this service (not 
now, but after setup is complete e.g. for server maintenance), the pgAgent 
service will need to be started as well.


### Create postgres OpenClinica Report Database
The creation of the database is handled by a package of scripts called 
*sqldatamart*. A batch file accepts settings for the database which are 
substituted into the scripts where necessary. The setup needs to be run as a 
superuser because it requires a 'CREATE EXTENSION' statement for the foreign 
data wrapper, which can only be executed by superusers.

The build process is controlled by the *dm_build_commands* script. The script 
includes variables which must be provided to psql during the running of the 
script. The provided *setup_sqldatamart* Windows batch file sets and passes in 
the variables. 

- Edit the *setup_sqldatamart* bat file *set* statements to match the values 
  relevant to the environment.
- Run the *setup_sqldatamart* bat file.