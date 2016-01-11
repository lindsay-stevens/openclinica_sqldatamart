/* 
    Stata 14 may detect long-ish string columns as strL type, which happens to 
    sometimes show mysterious binary zeroes: "\0". If the string is less than 
    2045 characters it can be safely converted to fixed-length without losing 
    any data. Doing so happens to remove any binary zeroes.
    
    The following code will identify strL variables and cast them to the maximum fixed-length string type, str2045.
*/
ds, has(type strL)
local longstr `r(varlist)'
recast str2045 `longstr', force
