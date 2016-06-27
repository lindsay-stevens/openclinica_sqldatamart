* Extension code to save OpenClinica data by site as Excel XSLX.
*   1. Run the stata script generator, but comment out the "do" step so that 
*       the script is not executed immediately after being generated.
*   2. Open the generated script and do a find and replace:
*       - find: save "`snapshotdir'/
*       - replace: savex , snap(`snapshotdir') oids(`oids') "
*     This should produce commands that look like the following:
*       savex , snap(`snapshotdir') oids(`oids') "ig_a1007_centrallab"
*   3. Insert the following code into the top of the generated script, after 
*       the macro declarations but before the first "odbc load" command.
*   4. Update the below macro "filter_study_name_schema" to match the value 
*       entered to the generator script.        
local filter_study_name_schema = "activate"
set more off

* Retrieve a list of site_oids which have subjects in the study, save in "oids".
local site_sql = "select distinct on (site_oid) site_oid from `filter_study_name_schema'.subjects"
odbc load, exec("`site_sql'") connectionstring("`odbc_string_or_file_dsn_path'")
qui levelsof site_oid, local(oids)
clear

* Create a folder to save files in, for each of the sites in "oids"
foreach i of local oids {
    local outdir "`snapshotdir'/`i'"
    cap mkdir "`outdir'"
}

cap program drop savex
program define savex
    * Save the dataset as XLSX to the site folder, for each site in "oids".
    *
    * A note on the "syntax" command:
    * The syntax command only allows named options after a comma, so to allow 
    * no non-option commands, there is "[anything]", which is actually just a 
    * space in all the commands. The star "*" is a catch-all for positional 
    * arguments but for some reason omits the second double quote in a double 
    * quoted string positional argument.
    *   
    * Parameters.
    * :snap: The snapshot directory macro.
    * :oids: The site oids list macro.
    * :Arg1: name of file to save as.
    syntax [anything], snap(string) oids(string) *
    
    * Alias the "options" positional args so we can work with the string.
    local file `options'"
    * Trim off the ".dta" extension from the filename, if present.
    if ustrright("`file'", 4) == ".dta" {
        local file = ustrleft("`file'", length("`file'")-4)
    }
    foreach i of local oids {
        * For item group data sets or the subject list, filter by oid.
        local outfile = "`snap'/`i'/`file'.xlsx".
        local filter "" 
        if ustrleft("`file'", 3) == "ig_" | "`file'" == "subjects" {
            local filter if site_oid == "`i'"
        }
        * Export the (possibly filtered) data set, if there's >0 observations.
        qui count `filter'
        if r(N) > 0 {
            export excel using "`outfile'" `filter', firstrow(varlabels) replace
        }
    }
end