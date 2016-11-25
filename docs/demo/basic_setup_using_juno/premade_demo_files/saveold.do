/* Use to convert a directory of Stata files e.g. version 14 to version 11. */
/* Open a command prompt in the directory where the .dta files are, then run: */
/* for %F in (*.dta) do ("c:\Program Files (x86)\Stata14\Stata-64.exe" /e saveold.do "%~nF") */

args filename
use `filename'.dta
quietly ds, has(type string)
quietly recast str244 `r(varlist)'
saveold `filename'_v11.dta, replace v(11)
