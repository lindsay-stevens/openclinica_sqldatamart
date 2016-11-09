:: Preparation and variables
@SET study_schema=the_juno_diabetes_study
@SET stata_output_path=%~dp0stata_output
@SET stata_script_path=%stata_output_path%\stata_script_from_psql.do

@SET odbc_1=DRIVER={PostgreSQL Unicode(x64)};
@SET odbc_2=DATABASE=openclinica_fdw_db;SERVER=localhost;PORT=5446;
@SET odbc_3=UID=postgres;PWD=password;
@SET odbc_4=TextAsLongVarchar=0;UseDeclareFetch=0;
@SET odbc_connection_string=%odbc_1%%odbc_2%%odbc_3%%odbc_4%

call %~dp0util_restart.bat

psql -d openclinica_fdw_db -c "COPY (SELECT public.dm_snapshot_code_stata('%study_schema%', '%stata_output_path%', '%odbc_connection_string%')) TO '%stata_script_path%';"

echo.
echo Finished step 4. This window can be closed.
echo To keep the database running, leave this window open.
echo.
echo The exported Stata script should be at: %stata_script_path%
echo.
echo The ODBC connection string used in the Stata script: %odbc_connection_string%
echo.