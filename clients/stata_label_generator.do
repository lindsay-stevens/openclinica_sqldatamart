** set up environment
capture log close
log using stata_labelling_log.log, replace

set more off

** this program outputs a labelling do file for each item group
** step 1 is get all the variable labels from metadata_crf_ig_item
** step 2 is get all the variable value labels from response_set_labels

** step 1
clear all

** load the item definitions file
use "metadata_crf_ig_item.dta"

** generate the variable labelling commands
gen varlabel = "lab var " + lower(item_name) + `" ""' + item_description + `"""'

** make an ordering variable
gen order = _n

** tag the first occurrence of each labelling command, use item_oid in case item_name is reused
by varlabel item_oid (order), sort: gen varlabel_first = _n == 1

** tag the first occurrence of each item group oid
by item_group_oid (order), sort: gen item_group_oid_first = _n == 1

** get the observation count in a local macro
su order, meanonly
local obscount `r(max)'

** loop through each unique item group, note that i is the observation number
forvalues i=1/`obscount' {

	** only act on each item group once
	if item_group_oid_first[`i'] == 1 {
	
		** store the current item group oid for reuse
		scalar item_group_oid_current = item_group_oid[`i']
		
		** create a short but unique name for the file handle
		local file_handle=substr(item_group_oid_current,1,8)
		
		** create the file name
		local file_name=item_group_oid_current+"_labels.do"
	
		** open the file for replace, name it using the full item group name
		file open `file_handle' using `file_name', write replace
		
		** loop through each command list and write it, followed by a newline
		forvalues j=1/`obscount' {
		
			** store the current varlabel for reuse
			scalar varlabel_current = varlabel[`j']
			
			** only act on each varlabel once
			if item_group_oid[`j'] == item_group_oid_current & varlabel_first[`j'] == 1 {
			
				** write the varlabel to the file, followed by a newline
				file write `file_handle' (varlabel_current) _n
			}
		}
		** close the file and move on to the next item group, if any
		file close `file_handle'
	}
}

** step 2
clear

** load the response labels file
use "response_set_labels.dta"

** generate the label variable labelling commands
gen varlabel = "lab var " + lower(item_name) + `"_label ""' + item_description + `" label""'

** generate the value labelling commands
gen vallabel = "lab def " + lower(item_name) + "_lbl " + option_value + `" ""' + option_text + `"", modify"'

** generate the value labelling apply commands
gen valvarlbl = "lab val " + lower(item_name) + " " + lower(item_name) + "_lbl"

** make an ordering variable
gen order = _n

** tag the first occurrence of each varlabel command, use item_oid in case item_name is reused
by varlabel item_oid (order), sort: gen varlabel_first = _n == 1

** tag the first occurrence of each vallabel command, use item_oid in case item_name is reused
by vallabel item_oid (order), sort: gen vallabel_first = _n == 1

** tag the first occurrence of each valvarlbl command, use item_oid in case item_name is reused
by valvarlbl item_oid (order), sort: gen valvarlbl_first = _n == 1

** tag the first occurrence of each item group oid
by item_group_oid (order), sort: gen item_group_oid_first = _n == 1

** get the observation count in a local macro
su order, meanonly
local obscount `r(max)'

** loop through each unique item group, note that i is the observation number
forvalues i=1/`obscount' {

	** only act on each item group once
	if item_group_oid_first[`i'] == 1 {
	
		** store the current item group oid for reuse
		scalar item_group_oid_current = item_group_oid[`i']
		
		** create a short but unique name for the file handle
		local file_handle=substr(item_group_oid_current,1,8)
		
		** create the file name
		local file_name=item_group_oid_current+"_labels.do"
	
		** open the file for replace, name it using the full item group name
		file open `file_handle' using `file_name', write append
		
		** loop through each varlabel command and write it, followed by a newline
		forvalues j=1/`obscount' {
		
			** store the current varlabel for reuse
			scalar varlabel_current = varlabel[`j']
			
			** only act on each varlabel once
			if item_group_oid[`j'] == item_group_oid_current & varlabel_first[`j'] == 1 {
			
				** write the varlabel to the file, followed by a newline
				file write `file_handle' (varlabel_current) _n
			}
		}
		
		** loop through each vallabel command and write it, followed by a newline
		forvalues k=1/`obscount' {
		
			** store the current vallabel for reuse
			scalar vallabel_current = vallabel[`k']
			
			** only act on each vallabel once
			if item_group_oid[`k'] == item_group_oid_current & vallabel_first[`k'] == 1 {
			
				** write the vallabel to the file, followed by a newline
				file write `file_handle' (vallabel_current) _n
			}
		}
		
		** loop through each vallabel command and write it, followed by a newline
		forvalues l=1/`obscount' {
		
			** store the current valvarlbl for reuse
			scalar valvarlbl_current = valvarlbl[`l']
			
			** only act on each valvarlbl once
			if item_group_oid[`l'] == item_group_oid_current & valvarlbl_first[`l'] == 1 {
			
				** write the valvarlbl to the file, followed by a newline
				file write `file_handle' (valvarlbl_current) _n
			}
		}
		
		** close the file and move on to the next item group, if any
		file close `file_handle'
	}
}

** close the log file
log close
