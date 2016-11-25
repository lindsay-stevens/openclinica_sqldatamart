# Advanced Setup


## Contents
- [Terminology](#terminology)
- [Introduction](#introduction)
- [OpenClinica PostgreSQL Configuration](#openclinica-postgresql-configuration)
    - [OC1 Database Read-only Role](#oc1-database-read-only-role)
    - [OC2 PostgreSQL Settings](#oc2-postgresql-settings)
        - [OC2.1 Global Configuration (Optional)](#oc21-global-configuration-optional)
        - [OC2.2 Connection Methods (Scenario 2 only)](#ocdm22-connection-methods-scenario-2-only)
    - [OC3 Encrypted Connections](#oc3-encrypted-connections)
        - [OC3.1 Certificate Files](#oc31-certificate-files)
        - [OC3.2 PostgreSQL Settings](#oc32-postgresql-settings)
- [DataMart PostgreSQL Configuration](#datamart-postgresql-configuration)
    - [OCDM1 Install PostgreSQL](#ocdm1-install-postgresql)
    - [OCDM2 Certificate Files](#ocdm2-certificate-files)
    - [OCDM3 PostgreSQL Settings](#ocdm3-postresql-settings)
        - [OCDM3.1 Global Configuration](#ocdm31-global-configuration)
        - [OCDM3.2 Connection Methods](#ocdm32-connection-methods)
        - [OCDM3.3 User Mappings](#ocdm33-user-mappings)
    - [OCDM4 Build DataMart](#ocdm4-build-datamart)
    - [OCDM5 Domain Service Account](#ocdm5-domain-service-account)
        - [OCDM5.1 Domain Admin Tasks](#ocdm51-domain-admin-tasks)
        - [OCDM5.2 Database Role](#ocdm52-database-role)
        - [OCDM5.3 Database Runner](#ocdm53-database-runner)
- [Certificate How To's](#certificate-how-tos)
    - [Prepare the CA certificate](#prepare-the-ca-certificate)
    - [Get a New Certificate](#get-a-new-certificate)
    - [Use Tomcat's Certificate](#use-tomcats-certificate)


## Terminology
The following terminology and abbreviations are used in this document.

- "AD": Active Directory. The AD functions relevant to DataMart are LDAP user information, Kerberos authentication, and DNS records. For Linux, FreeIPA can provide these functions, or they can be done separately with OpenLDAP, Kerberos and BIND.
- "DSA": Domain Service Account. An AD domain account created for the purpose of running the OCDM service.
- "FQDN": Fully Qualified Domain Name. A name that maps to an IP address. "Fully Qualified" means that the whole name is provided (e.g. "ocdm.mydomain.org") rather than only part of it (e.g. "ocdm").
- "OC": OpenClinica
- "OCDM": OC Community DataMart
- "PG": PostgreSQL
- "PGDATA": the directory containing the PG server files, including all configuration files. By default it is named "data" and exists in the installation directory. For example: `C:\Program Files\PostgreSQL\9.6\data`.
- "SSPI": a Windows-specific authentication interface supported by PG. For Linux, GSSAPI provides equivalent functionality for PG. Since SSPI supports both Kerberos authentication and the less secure NTLM protocol, the intended method for DataMart is specified as SSPI/Kerberos.
- "pg_hba.conf": the PG Host-Based Authentication file. Configures the "how", "who", "to what", and "where from" of user connections to PG.
- "pg_ident.conf": the PG User Name Maps file. Configures mappings of system user names to PG role names using pattern matching.
- "postgresql.conf": the PG Global Configuration file. Stores all configuration data not covered by "pg_hba.conf" and "pg_ident.conf".


## Introduction
This document describes how to deploy Community DataMart in an "Advanced" setting, which provides the following advantages over the "Basic" setup.

- Improved performance by using separate PostgreSQL servers for OC and OCDM (with encrypted connections if they are on separate machines),
- Encrypted connections between DataMart PostgreSQL and clients,
- Integrated Authentication against Active Directory via SSPI/Kerberos.

After completing this setup, continue to the "Maintenance" instruction document which describes how to keep DataMart up to date.

The deployment scenarios described in this document are Scenarios 1 and 2, as illustrated below:

```
Scenario 1 (Best):
  - Machine 1
    - PostgreSQL Server 1
      - OpenClinica
  - Machine 2
    - PostgreSQL Server 2
      - DataMart

Scenario 2 (OK):
  - Machine 1
    - PostgreSQL Server 1
      - OpenClinica
    - PostgreSQL Server 2
      - DataMart

Scenario 3 (Not so good, not covered):
  - Machine 1
    - PostgreSQL Server 1
      - OpenClinica
      - DataMart
```

These instructions assume deployment on Windows Server. The Windows-specific parts are the syntax of command-line examples and the Active Directory integration. The AD integration includes running the DataMart PostgreSQL server with a domain account, and using AD for client authentication. It would be possible to set up DataMart in an equivalent manner on Linux, but until a guide is contributed here, look online for instructions for this and the enormous range of other authentication options.

Some PostgreSQL configurations are suggestions relating to improving performance through adjusting resource allocation. This generally follows advice available online, for example:
- [PG tuning advice for web applications](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [PgTune](https://github.com/gregs1104/pgtune)


[Back to Contents](#contents)


## OpenClinica PostgreSQL Configuration
Steps in this section should be done on the server where the OC PG server is installed. Referring to the deployment scenarios shown in the [Introduction](#introduction)), the following steps should be completed:

- Scenario 1: OC1, OC2.1, and OC3.
- Scenario 2: OC1 and OC2.


### OC1 Database Read-only Role
In this step, a user will be created which has read-only access to the OC database. OCDM will connect as this user to retrieve data using foreign tables. Due to the design of foreign tables, this user can only use password authentication, not SSPI/Kerberos.

- Connect to the OC database as a privileged user and run the following SQL, which creates a role with read-only permissions.

```sql
CREATE ROLE "openclinica_select" NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE openclinica to openclinica_select;
GRANT USAGE ON SCHEMA public to openclinica_select;

/* 
In PostgreSQL 9.0+ the following temporary function call can be replaced with:
GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;
*/

CREATE FUNCTION public.grant_select_on_all_tables_in_schema()
  RETURNS VOID AS $b$
DECLARE r record;
BEGIN
FOR r IN
  SELECT 
    $s$GRANT SELECT ON $s$ || relname || $s$ TO openclinica_select;$s$ as gnt
  FROM 
    pg_class 
  INNER JOIN pg_namespace 
    ON pg_namespace.oid = pg_class.relnamespace
  WHERE 
    nspname = 'public' 
    AND relkind IN ('r', 'v')
LOOP
    EXECUTE r.gnt;
END LOOP;
END;$b$ LANGUAGE plpgsql VOLATILE;
SELECT public.grant_select_on_all_tables_in_schema();
DROP FUNCTION public.grant_select_on_all_tables_in_schema();
```

- Next, update the following command with a suitably good password. Then run the command, which creates a login role with the above permissions assigned to it.

```sql
CREATE ROLE ocdm_fdw WITH LOGIN ENCRYPTED PASSWORD 'aGoodPassword'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT openclinica_select TO ocdm_fdw;
```


### OC2 PostgreSQL Settings
The following sections describe steps for configuring connections from the OCDM user, and optional performance tuning suggestions.


#### OC2.1 Global Configuration (Optional)
In `postgresql.conf`, if there is has been no previous performance tuning, the following suggestions may improve performance of OC. These values assume a machine with 2GB available (4GB total, minus 2GB for Tomcat).

```ini
shared_buffers = 512MB  # RAM / 4. On Windows, max 512MB.
work_mem = 16MB  # RAM / max_connections (default 100).
maintenance_work_mem = 128MB  # RAM  / 16. Stay below 2GB.
checkpoint_completion_target = 0.7  # reduce disk load in exchange for longer crash recovery time.
effective_cache_size = 1536MB  # (RAM * 3) / 4.
default_statistics_target = 200  # increased for better query plans (default 100).
```

Suggested logging settings can be copied from the section [OCDM3.1 Global Configuration](#ocdm3-1-global-configuration)


#### OC2.2 Connection Methods (Scenario 2 only)
In `pg_hba.conf`, add the following row to allow the OC role for OCDM to connect using a local unencrypted connection and a password.

```
# TYPE   DATABASE             USER       ADDRESS        METHOD
host     openclinica_fdw_db   ocdm_fdw   127.0.0.1/32   md5
```


### OC3 Encrypted Connections


#### OC3.1 Certificate Files
To use encrypted connections between OC PG and OCDM PG, the following files must be prepared and filed as follows. For a guide on preparing these files, refer to the section [Certificate How To's](#certificate-how-to-s).

- `server.crt`: the OC PG server public certificate. Put this in OC PGDATA.
- `server.key`: the server private key. Put this in OC PGDATA.

Unlike OCDM, a `root.crt` is not required in OC PGDATA because this file is used by clients to verify host certificates. OC PG is not connecting as a client to any other hosts for DataMart.


#### OC3.2 PostgreSQL Settings
Add or change the following OC PG configuration values.

- In `pg_hba.conf`, add the following row to allow the OC role for OCDM to connect over an encrypted connection. Ensure that the database name and OCDM IP address values are correct.

```
# TYPE    DATABASE      USER       ADDRESS      METHOD
hostssl   openclinica   ocdm_fdw   OCDM_IP/32   md5
```

- In `postgresql.conf`, change the following value to enable encrypted connections.

```
ssl = on
```

- In `postgresql.conf`, if OC PG is version 9.4 or earlier, change the following value.
    - This setting disables SSL renegotiation, which was deprecated in PG 9.5 and causes the server to drop / renegotiate connections after a quantity of data (default 512MB) has been transferred.
    - The default setting can cause OCDM maintenance jobs to fail, for example if OCDM PG is 9.5 or later and OC PG is 9.4 or earlier, OCDM PG will consider the connection termination for SSL renegotiation to be an error.

```
ssl_renegotiation_limit = 0
```


[Back to Contents](#contents)


## DataMart PostgreSQL Configuration
Steps in this section should be done on the server where the OCDM PG server to be installed. Referring to the deployment scenarios shown in the [Introduction](#introduction)):

- Both scenarios 1 and 2 require all steps to be completed.
- If deploying to Linux or using an authentication method other than Active Directory, complete all steps except OCDM3.3, and all of OCDM5.


### OCDM1 Install PostgreSQL
Install the most recent PostgreSQL available. If the database service was started during installation, stop it for now as the next steps include updating settings which only take effect on server restart. 

If using the EDB Installer for Windows, complete the optional installation on pgAgent, which will be used in the maintenance setup.


### OCDM2 Certificate Files
To use encrypted connections between OCDM PG and clients, the following 3 files must be prepared and filed as follows. For a guide on preparing these files, refer to [Certificate How To's](#certificate-how-to-s).

- `server.crt`: the OCDM PG server public certificate. Put this in OCDM PGDATA.
- `server.key`: the server private key. Put this in OCDM PGDATA.
- `root.crt`: the public certificate of the institution that issued the OC PG `server.crt`, required to verify the authenticity of OC PG `server.crt`.

The `root.crt` corresponding to OCDM PG's `server.crt` will need to be distributed to users / DataMart clients, as described in the "Clients" section of the OCDM documentation. In brief, the OCDM PG `root.crt` will go in the user's home folder, i.e.:

- Windows: `%APPDATA%\postgresql\root.crt`, e.g. `C:\Users\Lindsay\AppData\Roaming\postgresql\root.crt`.
- Linux: `~/.postgresql/root.crt`.


### OCDM3 PostgreSQL Settings
The following sections describe steps for configuring encrypted client connections, enhanced performance, and integrated authentication.


#### OCDM3.1 Global Configuration
In `postgresql.conf`, locate, and add or change the following settings. Settings are disabled by placing a `#` at the start of the line; remove this if present for any of these settings. Ensure that the `port` setting is correct.

The suggested resource allocation values assume a machine with 4GB available and 2 CPUs. Some of these values are set much higher during maintenance, also assuming 4GB is available.

```ini
# - Connection Settings -
listen_addresses = '*' # Allow external connections. Controlled further in pg_hba.conf.
port = 5433  # Must not already be in use.
max_connections = 100  # AD/Kerberos with psqlODBC doesn't pool connections so this needs to be high.

# - Security and Authentication -
ssl = on  # allow encrypted connections
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'root.crt'

# - Memory -
shared_buffers = 512MB  # RAM / 4. On Windows, max 512MB.
work_mem = 40MB  # RAM / max_connections (default 100).
maintenance_work_mem = 512MB  # RAM / 8.

# - Asynchronous Behavior - POSTGRES 9.6 AND LATER ONLY
max_worker_processes = 10		# default 8 (incl. maint), add 2 assuming taken by parallel workers.
max_parallel_workers_per_gather = 2	# taken from max_worker_processes pool.

# - Checkpoints -
checkpoint_segments = 128  # reduce disk load in exchange for longer crash recovery time.
checkpoint_completion_target = 0.9  # reduce disk load in exchange for longer crash recovery time.

# - Planner Cost Constants -
effective_cache_size = 3072MB  # (RAM * 3) / 4.

# - Other Planner Options -
default_statistics_target = 1000  # increased for amazing query plans (default 100).

# - Where to Log -
log_destination = 'csvlog' # log to csv format so logs can be analysed more easily.
logging_collector = on  # enable logging
log_filename = 'postgresql-%Y-%m-%d.log'  # log daily file names like postgresql-2015-01-20.log
log_rotation_size = 0  # do not rotate log files based on log file size

# - What to Log -
log_connections = on  # log client connections
log_disconnections = on  # log client disconnections
log_duration = on  # log duration of submitted queries
log_statement = 'all'  # log all submitted statements

# - Lock Management -
max_locks_per_transaction = 1000  # Refreshing matviews can generate a large amount of locks
```


#### OCDM3.2 Connection Methods
In `pg_hba.conf`, locate, and add or change the settings shown below.

The order is important, as connections are checked against these rules in sequence. The first match is attempted, and if that fails, no others are attempted. After a match is satisfied, the authentication method is attempted (e.g. password is checked).

In reference to each row, the settings do the following things.

- Allow unencrypted connections to any database using the "postgres" superuser, from the same machine over IPv4, using a password.
- Allow unencrypted connections to any database using the DSA user, from the same machine over IPv4, using a password.
    - Change "DSA" to the local name of your DSA, e.g. "sa-ocdm" from "MYDOMAIN\sa-ocdm".
- Allow encrypted connections to any database using any username, from the specified IP range, using Active Directory authentication (referring to the map name "mapsspi" in `pg_ident.conf`, allowing only users from the domain "myDomain").
    - Change "DOMAIN_IP/MASK" to the range the domain users would be connecting from.
    - Change "MYDOMAIN" to the name of the domain users would be connecting from.
- Same as above, except demonstrating that it's possible to add extra rows with alternate IP range and mask values. In this example, the apparent IP address of domain users is different when they're connected over a VPN (e.g. working remotely) than when connecting on-site.
- Same as the first row, except for a local IPv6 address.
- Same as the second row, except for a local IPv6 address.

```
# TYPE    DATABASE   USER       ADDRESS          METHOD
host      all        postgres   127.0.0.1/32     md5
host      all        DSA        127.0.0.1/32     sspi map=mapsspi include_realm=1 krb_realm=MYDOMAIN
hostssl   all        all        DOMAIN_IP/MASK   sspi map=mapsspi include_realm=1 krb_realm=MYDOMAIN
hostssl   all        all        VPN_IP/MASK      sspi map=mapsspi include_realm=1 krb_realm=MYDOMAIN
host      all        postgres   ::1/128          md5
host      all        DSA        ::1/128          sspi map=mapsspi include_realm=1 krb_realm=MYDOMAIN
```

If not using SSPI/Kerberos (or equivalent) for authentication:
  - Replace the "sspi ..." values in the "METHOD" column. Refer to the postgres documentation for the available methods.
  - Remove rows 2 and 6, which allow the DSA user to connect.


#### OCDM3.3 User Mappings
If not using SSPI/Kerberos for authentication, skip this section.

In `pg_ident.conf`, locate, and add or change the settings shown below.

In reference to each column, the settings do the following things.

- "mapname": must match the sspi map name referred to in `pg_hba.conf` for it to be applied. 
- "system-username": a regular expression for finding the user name in the one provided on connection. This pattern looks for something like `localname@myDomain`, and matches the part before the `@`, which would be `localname`.
    - Change "myDomain" to the name of the domain users would be connecting from.
- "pg-username": regular expressions can match multiple pieces of a string. In this case the pattern is only looking for one piece, so the first piece is sent to postgres to see if it matches a valid login role name.

```
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
mapsspi       /^(.*)@myDomain$          \1
```

An important thing to note about user name mapping is that on Windows, the matching of domain local names to PG role names is always case sensitive. The setting named "krb_caseins_users" in `postgresql.conf` is to allow case insensitivity for GSSAPI authentication (typically on Linux), and has no effect on SSPI on Windows. So it is important that DataMart users log in to the domain using a consistently cased name. DataMart uses first letter capitalised, e.g. "Lstevens".


#### OCDM4 Build DataMart
In the root folder of the DataMart repository (where the LICENSE file is), there is a script named `setup_sqldatamart`. This script initiates the build process and provides configuration values to `dm_build_commands.sql`, which in turn orchestrates the rest of the build process.

Edit the `setup_sqldatamart` script so that all the variables are correct for the deployment environment, then execute the script. As it progresses, it will show output related to each step.

For now, the script is quite simple, so it'll either work perfectly, fail mysteriously, or fail spectacularly. The way to tell between the first two outcomes is to inspect the created database.


[Back to Contents](#contents)


### OCDM5 Domain Service Account
To be able to use SSPI/Kerberos, the OCDM PG server must be run using a domain account. This section describes the necessary configuration steps.


#### OCDM5.1 Domain Admin Tasks
A domain administrator needs to ensure that the account has:

- Privileges to log in to the OCDM machine as a service,
- A service principal name (SPN) set for OCDM PG.
    - If configured, clients can use SSPI/Kerberos.
    - If not configured, clients may be able to use the less secure SSPI/NTLM, if it is available.

An example of the command to set the SPN, which the domain administrator must run, is shown below. The components of this command are:

- `setspn -s`: add a new service principal name to the domain (replace "-s" with "-d" to delete the SPN).
- `POSTGRES/ocdm.mydomain.org`: the service is called "POSTGRES", and is being run the OCDM server whose FQDN is "ocdm.mydomain.org".
    - Change this FQDN to the one used in the deployment environment.
- `MYDOMAIN\sa-ocdm`: the service is being run on the domain "MYDOMAIN" by a user named "sa-ocdm".
    - Change this to the domain and local name of the one created for this purpose.

```
setspn -s POSTGRES/ocdm.mydomain.org MYDOMAIN\sa-ocdm
```


#### OCDM5.2 Database Role
In this step, a user will be created for the DSA to connect to OCDM with. In the previous step [OCDM3.2](#ocdm3-2-connection-methods), local connections for the DSA should have been configured. The DSA will be used to run database maintenance tasks (refer to docs/maintenance). If some other user will be running maintenance tasks, this step can be skipped.

- Connect to the OCDM database as a privileged user and run the following SQL, which creates a role with "dm_admin" permissions. These permissions allow full control of the OCDM database, which is required for maintenance tasks.

```sql
CREATE ROLE datamart LOGIN
  NOSUPERUSER INHERIT NOCREATEDB CREATEROLE NOREPLICATION;
GRANT dm_admin TO datamart;
```


#### OCDM5.3 Database Runner
To be able to run OCDM PG, the DSA must first have full control of OCDM PGDATA. To set this:

- Right-click PGDATA and choose "Properties",
- On the "Security" tab, click "Edit", then "Add",
- For the "Object name", enter the full name of the DSA, click "Check Names", and select the correct record for the user.
- Click "OK" on each pop-up window until "Properties" is closed.

Next, change the OCDM PG service user to the DSA. To do this on Windows:

- Press the "Windows" key, search for `services.msc`, and click the result (or press Enter).
- Locate the OCDM PG service, which for example may be named `postgresql-x64-9.6`.
- Right-click the service name and choose "Properties",
    - If the service is currently running, click "Stop".
- On the "Log On" tab, choose "This account", and click "Browse".
- For the "Object name", enter the full name of the DSA,
- Click "Check Names", and select the correct record for the user.
- Complete the the DSA password and confirm password fields.
- Click "OK" to close "Properties" and exit the service manager.


If desired, the database service can be set to perform an action if there is a problem with the service. In that case, in the service properties under "Recovery", choose the recovery option "Run a program". The program to run is selected in the area below the recovery action options. The selected program could be something like a script that notifies an administrator of the problem by sending an email.

[Back to Contents](#contents)


## Certificate How To's
This section includes tips relevant to the preparation of certificate files required for encrypted connections.


### Prepare the CA certificate


#### Background
When making a encrypted connection, behind-the-scenes activity involves the host server providing it's public certificate to the client. The server certificate is then used to establish a shared secret that will be used to encrypt data sent over the connection. To improve the security of this process, the client should verify that the server host name matches the name on the certificate, and that the server certificate was issued by the trusted third party (a Certificate Authority, or CA) that it claims to have been issued by.

In order to complete this verification, the client needs a copy of the CA public certificate. For greater security, many CA's issue certificates using one or more intermediate certificates. In this case, the client needs to have the root and all intermediate public certificates in order to verify the server certificate.

The operating system and all browsers maintain a list of "trustworthy" CA root and intermediate certificates for users so that all this verification work is transparent. However, like many other server softwares, PostgreSQL (as of 9.6) does not use these trust stores. The CA public certificate(s) must be obtained then provided manually in a plain text format. The collection of CA certificates is sometimes referred to as a "CA bundle".


#### Obtaining the CA Bundle
The CA's website should list the public certificates used for issuing certificates. For example, the CA "QuoVadis" has a [CA Certificate Download page](https://www.quovadisglobal.com/QVRepository/DownloadRootsAndCRL.aspx). 

In Windows, double click the server certificate and view the "Certification Path" tab to find the name of the correct CA certificates to download. Alternatively, inspect the certificate using OpenSSL with the following command:

```
openssl x509 -in server.crt -noout -text
```

The required certificate format is "PEM". 

- Create a new text file named `root.crt`.
- Copy and paste the content of all certificates in the Certification Path, in the issuing order, with the root last, i.e. for the path: Root -> Intermediate -> Server, paste as follows:

```
-----BEGIN CERTIFICATE-----

... intermediate certificate content ...

-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----

... root certificate content ...

-----END CERTIFICATE-----
```


### Get a New Certificate
Certificate Authority websites usually have detailed information on obtaining certificates. The process is:

- Generate a Certificate Signing Request (CSR). This is submitted to a CA.
- CA issues a certificate from the CSR: this is the "server.crt" public certificate.

The following is an example OpenSSL command to generate a CSR. Details to change include:

- C=AU : C = Country code; AU = Australia
- ST=NSW : ST = State code; NSW = New South Wales
- L=Kensington : L = Locality
- O=UNSW Australia : O = Organisation
- OU=KIRBY : OU = Organisational Unit; KIRBY = Kirby Institute
- CN=ocdm.example.org : CN = Common Name; ocdm.example.org = FQDN (full name) of the server.

```
C:\OpenSSL-Win32\bin\openssl.exe req -newkey rsa:4096 -sha512 -nodes -subj "/C=AU/ST=NSW/L=Kensington/O=UNSW Australia/OU=KIRBY/CN=ocdm.example.org" -out CSR.csr -keyout server.key
```

This produces two files:

- `CSR.csr`: the CSR to provide to the CA, and 
- `server.key`: the server's private key (basically, it's a password. Keep it secret!).


### Use Tomcat's Certificate
If a certificate has already been obtained for the OC Tomcat server using the Java Keytool, it is possible to extract and convert that certificate for use with PostgreSQL. This is only suitable for the OC PG certificate, and is only necessary in deployment Scenario 1 (separate OC / OCDM machines). The conversion process is as follows:

- First, convert the Java keystore into a PKCS12 format using keytool.
    - This produces a file `intermediate.p12`, which is a format that can then be converted to PEM.

```
%JAVA_HOME%\bin\keytool.exe -importkeystore -srckeystore tomcat.keystore ^
  -destkeystore intermediate.p12 -deststoretype PKCS12
```

- After issuing this command, respond to the prompts as follows.
    - The "destination keystore password" can be anything, it is only required temporarily.
    - The "source keystore password" should be in the Tomcat configuration file `server.xml`.
    - The messages about aliases, e.g. "Problem importing entry for alias xyz" will differ based on the CA and can be ignored.

```
Enter destination keystore password:
Re-enter new password:
Enter source keystore password:
Problem importing entry for alias qvroot: java.security.KeyStoreException: TrustedCertEntry not supported.
Entry for alias qvroot not imported.
Do you want to quit the import process? [no]:  no
Problem importing entry for alias qvint: java.security.KeyStoreException: TrustedCertEntry not supported.
Entry for alias qvint not imported.
Do you want to quit the import process? [no]:  no
Entry for alias mykey successfully imported.
Import command completed:  1 entries successfully imported, 2 entries failed or cancelled
```

- Next, convert the PKCS12 file `intermediate.p12` to a PEM format using OpenSSL.
    - The password is the "destination keystore password" set above.
    - This command produces a file named `extracted.pem`, containing the private key, public certificate, and CA certificate chain.

```
C:\OpenSSL-Win32\bin\openssl.exe pkcs12 -in intermediate.p12 -out extracted.pem -nodes
WARNING: can't open config file: /usr/local/ssl/openssl.cnf
Enter Import Password:
MAC verified OK
```

- Open `extracted.pem` in Notepad++. In the following steps, sections of this document will be copied into new files.
- Create a file `server.key` (the private key). Copy and paste in the section from `extracted.pem` that looks like the following:

```
-----BEGIN PRIVATE KEY-----

... private key content ...

-----END PRIVATE KEY-----
```

- Verify the `server.key` file in OpenSSL with the following command (no news is good news):

```
C:\OpenSSL-Win32\bin\openssl.exe rsa -in server.key -noout
```

- Create a file `server.crt` (the public certificate). Copy and paste in the section from `extracted.pem` that looks like the following:
    - There will be at least 2 of these sections; take the one that has your server name just above it, e.g. "friendlyName: CN=oc.example.org".

```
-----BEGIN CERTIFICATE-----

... public certificate content ...

-----END CERTIFICATE-----
```

- Create a file `root.crt` (the CA certificates). Copy and paste in the section(s) from `extracted.pem` that look like the following:
    - These should be listed in order of the Certification Path - see above section [Obtaining the CA Bundle](#obtaining-the-ca-bundle).
    - For example, say there is an intermediate certificate following "friendlyName: CN=QuoVadis Global SSL ICA G2", and then a root certificate following "friendlyName: CN=QuoVadis Root CA 2". These would be copied as follows:

```
-----BEGIN CERTIFICATE-----

... intermediate certificate content from QuoVadis Global SSL ICA G2 ...

-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----

... root certificate content from QuoVadis Root CA 2 ...

-----END CERTIFICATE-----
```


[Back to Contents](#contents)
