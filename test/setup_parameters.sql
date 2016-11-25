SELECT openclinica_fdw.fdw_setup(
  foreign_server_host_name := 'localhost',
  foreign_server_host_address := '127.0.0.1',
  foreign_server_port := '5446',
  foreign_server_database := 'openclinica',
  foreign_server_user_name := 'postgres',
  foreign_server_user_password := 'password'
  --datamart_admin_role_name := 'dm_admin',
  --foreign_server_openclinica_schema_name := 'public',
  --foreign_server_data_wrapper_kwargs := $s$, sslmode 'verify-full', sslrootcert 'root.crt'$s$
);