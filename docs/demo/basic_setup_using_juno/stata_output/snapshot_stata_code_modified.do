local odbc_string_or_file_dsn_path="DRIVER={PostgreSQL Unicode(x64)};DATABASE=openclinica_fdw_db;UID=postgres;PWD=password;SERVER=localhost;PORT=5446;TextAsLongVarchar=0;UseDeclareFetch=0"
local data_filter_string=""
local snapshotdir="C:/Users/Lstevens/Documents/repos/openclinica/openclinica_sqldatamart/docs/demo/basic_setup_using_juno/stata_output"
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_adver_aelog `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var ae_dton "AE Date of Onset"
lab var ae_sev "AE Severity Grade"
lab var ae_out "AE Outcome"
lab var ae_otout "AE Other Outcome"
lab var ae_dtre "AE Date of Resolution"
lab var ae_desc "AE Description"
lab var ae_act "AE Action Taken"
lab def ae_sev_lbl 2 "II", modify
lab def ae_out_lbl 4 "Unknown", modify
lab def ae_sev_lbl 5 "V", modify
lab def ae_out_lbl 5 "Other", modify
lab def ae_act_lbl 2 "Dose Interrupted", modify
lab def ae_act_lbl 1 "None", modify
lab def ae_sev_lbl 3 "III", modify
lab def ae_sev_lbl 4 "IV", modify
lab def ae_act_lbl 4 "Dose Modified", modify
lab def ae_act_lbl 3 "Dose Discontinued", modify
lab def ae_sev_lbl 1 "I", modify
lab def ae_out_lbl 3 "Ongoing", modify
lab def ae_out_lbl 2 "Recovered with sequelae", modify
lab def ae_out_lbl 1 "Recovered without sequelae", modify
lab val ae_out ae_out_lbl
lab val ae_sev ae_sev_lbl
lab val ae_act ae_act_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_adver_aelog.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_compl_cd `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var dth_cause "Cause of death"
lab var ae_sp "Describe AE"
lab var cd_ae "Adverse Event"
lab var cd_ae_1 "Adverse Event"
lab var cd_dth "Death"
lab var cd_dth_1 "Death"
lab var cd_miss "Missed appointment"
lab var cd_miss_1 "Missed appointment"
lab var cd_oth "Other"
lab var cd_oth_1 "Other"
lab var cd_wthdr "Patient withdrew"
lab var cd_wthdr_1 "Patient withdrew"
lab var cd_yn "Course of treatment completed as planned?"
lab var wthdr_sp "Specify reason for withdrawal"
lab var oth_sp "Specify other reason"
lab var miss_ev "Missed Event"
lab def cd_wthdr_1_lbl 1 "Patient voluntarily withdrew from study", modify
lab def cd_yn_lbl 1 "Yes", modify
lab def cd_yn_lbl 2 "No", modify
lab def cd_ae_lbl 1 "Adverse event occurred", modify
lab def cd_ae_1_lbl 1 "Adverse event occurred", modify
lab def cd_dth_lbl 1 "Patient expired", modify
lab def cd_dth_1_lbl 1 "Patient expired", modify
lab def cd_wthdr_lbl 1 "Patient voluntarily withdrew from study", modify
lab def cd_miss_lbl 1 "Patient missed appointment", modify
lab def cd_oth_1_lbl 1 "Other reason", modify
lab def cd_miss_1_lbl 1 "Patient missed appointment", modify
lab def cd_oth_lbl 1 "Other reason", modify
lab val cd_miss_1 cd_miss_1_lbl
lab val cd_yn cd_yn_lbl
lab val cd_wthdr_1 cd_wthdr_1_lbl
lab val cd_wthdr cd_wthdr_lbl
lab val cd_oth_1 cd_oth_1_lbl
lab val cd_oth cd_oth_lbl
lab val cd_miss cd_miss_lbl
lab val cd_dth_1 cd_dth_1_lbl
lab val cd_dth cd_dth_lbl
lab val cd_ae_1 cd_ae_1_lbl
lab val cd_ae cd_ae_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_compl_cd.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_conco_conmedlog `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var cm_ind "Indication"
lab var cm_freq "Frequency of Dose"
lab var cm_dose "Dose"
lab var cm_med "Medication name"
lab var cm_ongng "Ongoing status"
lab var cm_stdt "Start Date"
lab var cm_spdt "Stop Date"
lab def cm_freq_lbl 6 "Monthly", modify
lab def cm_ongng_lbl 2 "No", modify
lab def cm_ongng_lbl 1 "Yes", modify
lab def cm_freq_lbl 7 "As needed", modify
lab def cm_freq_lbl 1 "Hourly", modify
lab def cm_freq_lbl 2 "Daily", modify
lab def cm_freq_lbl 3 "2x per day", modify
lab def cm_freq_lbl 4 "3x per day", modify
lab def cm_freq_lbl 5 "Weekly", modify
lab val cm_ongng cm_ongng_lbl
lab val cm_freq cm_freq_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_conco_conmedlog.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_conco_conmeds `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var cm_yn "Is the subject taking any medications?"
lab def cm_yn_lbl 2 "No", modify
lab def cm_yn_lbl 1 "Yes", modify
lab val cm_yn cm_yn_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_conco_conmeds.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_demog_demo `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var dem_eth "Ethnicity"
lab var dem_edu "Highest level of education"
lab var dem_age "Calculated Age"
lab var dem_race_9 "Race"
lab var dem_race_8 "Race"
lab var dem_race_7 "Race"
lab var dem_race_6 "Race"
lab var dem_race_5 "Race"
lab var dem_race_4 "Race"
lab var dem_race_3 "Race"
lab var dem_race_2 "Race"
lab var dem_race_10 "Race"
lab var dem_race_1 "Race"
lab var dem_otrace "Other Race"
lab var dem_race "Race"
lab var dem_mar "Marital Status"
lab var dem_gen "Gender"
lab def dem_eth_lbl 3 "Unknown", modify
lab def dem_eth_lbl 2 "Non Hispanic", modify
lab def dem_eth_lbl 1 "Hispanic", modify
lab def dem_edu_lbl 6 "PhD", modify
lab def dem_edu_lbl 5 "Masters", modify
lab def dem_edu_lbl 4 "4 year college", modify
lab def dem_edu_lbl 3 "2 year college", modify
lab def dem_edu_lbl 2 "High School or GED", modify
lab def dem_edu_lbl 1 "Did not graduate from High School", modify
lab def dem_mar_lbl 5 "Unknown", modify
lab def dem_mar_lbl 4 "Widowed", modify
lab def dem_mar_lbl 3 "Divorced/Separated", modify
lab def dem_mar_lbl 2 "Married", modify
lab def dem_mar_lbl 1 "Single", modify
lab def dem_gen_lbl 2 "Female", modify
lab def dem_gen_lbl 1 "Male", modify
lab val dem_eth dem_eth_lbl
lab val dem_edu dem_edu_lbl
lab val dem_mar dem_mar_lbl
lab val dem_gen dem_gen_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_demog_demo.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_diabe_diabetes `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var retinopathy_mhstdat "Date of diagnosis"
lab var var36 "Severe hypoglycemic reaction (protocol-defined)"
lab var var38 "Date of most recent episode"
lab var sgoccur "Laser/photocoagulation therapy for diabetic retinopathy"
lab var autonomic_neuropathy_mhoccur "Autonomic neuropathy"
lab var autonomic_neuropathy_mhstdat "Date of diagnosis"
lab var diabetes_cmoccur "Was the subject ever treated with oral anti-hyperglycemic agent?"
lab var diabetes_cmstdat "If 'Yes,' first start date of treatment"
lab var retinopathy_mhoccur "Diabetic retinopathy"
lab var sgstdat "Date of treatment"
lab var diabetes_mhstdat "Date of diagnosis of diabetes"
lab var diabetic_nephropathy_mhoccur "Diabetic nephropathy"
lab var diabetic_nephropathy_mhstdat "Date of diagnosis"
lab var insulin_cmoccur "Was the subject ever treated with continuous insulin therapy, i.e. more than 2 weeks?"
lab var insulin_cmstdat "If 'Yes,' first start date of insulin treatment"
lab var var30 "Other diabetic neuropathy"
lab var var32 "Date of diagnosis"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_diabe_diabetes.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_eatin_habits `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sweets "Personal: Sweets"
lab var adult "Adults 18 or older"
lab var children "How many children under 18 years of age are living in your household?"
lab var cookfat "Personal: Cooking fats"
lab var cookfat_1 "Personal: Cooking fats"
lab var cookfat_2 "Personal: Cooking fats"
lab var cookfat_3 "Personal: Cooking fats"
lab var cookfat_4 "Personal: Cooking fats"
lab var cookfat_5 "Personal: Cooking fats"
lab var cookfat_6 "Personal: Cooking fats"
lab var cookfat_7 "Personal: Cooking fats"
lab var cookfat_8 "Personal: Cooking fats"
lab var dairy "Personal: Dairy products"
lab var dinner "Dinner with members of household"
lab var fruits "Personal: Fruits"
lab var lvalone "Do you live alone?"
lab var meat "Personal: Meats"
lab var othercook "Other cooking fats"
lab var sugartsp "Personal: Sugar"
lab var veggie "Personal: Veggies"
lab var vitsupp "Personal: Vitamins"
lab def veggie_lbl 4 "4-5 days/week", modify
lab def adult_lbl 1 "1", modify
lab def adult_lbl 2 "2", modify
lab def adult_lbl 3 "3", modify
lab def adult_lbl 4 "4", modify
lab def adult_lbl 5 "5", modify
lab def adult_lbl 6 "6 or more", modify
lab def children_lbl 0 "None", modify
lab def children_lbl 1 "1", modify
lab def children_lbl 2 "2", modify
lab def children_lbl 3 "3", modify
lab def children_lbl 4 "4", modify
lab def children_lbl 5 "5", modify
lab def children_lbl 6 "6 or more", modify
lab def dairy_lbl 0 "0-1 day/week", modify
lab def dairy_lbl 2 "2-3 days/week", modify
lab def dairy_lbl 4 "4-5 days/week", modify
lab def dairy_lbl 6 "6-7 days/week", modify
lab def dinner_lbl 0 "0-1 day/week", modify
lab def dinner_lbl 2 "2-3 days/week", modify
lab def dinner_lbl 4 "4-5 days/week", modify
lab def dinner_lbl 6 "6-7 days/week", modify
lab def fruits_lbl 0 "0-1 day/week", modify
lab def fruits_lbl 2 "2-3 days/week", modify
lab def fruits_lbl 4 "4-5 days/week", modify
lab def fruits_lbl 6 "6-7 days/week", modify
lab def lvalone_lbl 1 "Yes", modify
lab def lvalone_lbl 0 "No", modify
lab def meat_lbl 0 "0-1 day/week", modify
lab def meat_lbl 2 "2-3 days/week", modify
lab def meat_lbl 4 "4-5 days/week", modify
lab def meat_lbl 6 "6-7 days/week", modify
lab def sweets_lbl 0 "0-1 day/week", modify
lab def sweets_lbl 2 "2-3 days/week", modify
lab def sweets_lbl 4 "4-5 days/week", modify
lab def sweets_lbl 6 "6-7 days/week", modify
lab def veggie_lbl 0 "0-1 day/week", modify
lab def veggie_lbl 2 "2-3 days/week", modify
lab def adult_lbl 0 "None", modify
lab def veggie_lbl 6 "6-7 days/week", modify
lab def vitsupp_lbl 1 "Yes", modify
lab def vitsupp_lbl 0 "No", modify
lab val lvalone lvalone_lbl
lab val sweets sweets_lbl
lab val veggie veggie_lbl
lab val vitsupp vitsupp_lbl
lab val adult adult_lbl
lab val children children_lbl
lab val dairy dairy_lbl
lab val dinner dinner_lbl
lab val fruits fruits_lbl
lab val meat meat_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_eatin_habits.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_eatin_vitaminlog `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var amtvit "Daily Amount"
lab var namevit "Name of Vitamin or Supplement"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_eatin_vitaminlog.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_inclu_eligibility `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var ex_evinf "Exclusion: Is there evidence of active infection, recent infection, or chronic infection, requiring treatment with anti-infectives, hospitalization or IV antibiotics within the past 4 weeks?"
lab var in_fleng "Inclusion: Is the Subject fluent in English?"
lab var in_dt_ic "Inclusion: If yes, Date of Consent"
lab var in_cmssr "Inclusion: Is Subject is able and willing to comply with the study's survey requirements?"
lab var in_18yo "Inclusion: Is the Subject 18 years of age or older?"
lab var ex_strke "Exclusion: Has the Subject experienced a clinically significant stroke in the past?"
lab var ex_recnt "Exclusion: Has the Subject used another investigational drug within the past two months?"
lab var inex_elig "Eligibility Status"
lab var in_t2mel "Inclusion: Has the Subject been diagnosed with Type II diabetes mellitus for at least 24 months?"
lab var in_ic "Inclusion: Did the Subject provide informed consent?"
lab var in_heac1 "Inclusion: Was hemoglobin A1c between 8% to 10% at screening?"
lab var ex_preg "Exclusion: Is the Subject pregnant or planning on becoming pregnant during the study duration?"
lab var ex_ogtt "Exclusion: Does the Subject have a history of type 1 insulin-dependent diabetes?"
lab var ex_mentl "Exclusion: Does the Subject have any condition (eg, psychiatric illness) that, in the investigator's opinion, compromises the ability of the subject to participate in the study?"
lab var ex_hep "Exclusion: Does the Subject have active hepatic or renal disease?"
lab var in_fplgl "Inclusion: Does the Subject have a fasting plasma glucose ≤ 240 mg/dL (13.3 mmol/L)?"
lab def ex_evinf_lbl 2 "No", modify
lab def inex_elig_lbl 2 "Ineligible", modify
lab def inex_elig_lbl 1 "Eligible", modify
lab def in_t2mel_lbl 2 "No", modify
lab def in_t2mel_lbl 1 "Yes", modify
lab def in_ic_lbl 2 "No", modify
lab def in_ic_lbl 1 "Yes", modify
lab def in_heac1_lbl 2 "No", modify
lab def in_heac1_lbl 1 "Yes", modify
lab def in_fplgl_lbl 2 "No", modify
lab def in_fplgl_lbl 1 "Yes", modify
lab def in_fleng_lbl 2 "No", modify
lab def in_fleng_lbl 1 "Yes", modify
lab def in_cmssr_lbl 2 "No", modify
lab def in_cmssr_lbl 1 "Yes", modify
lab def in_18yo_lbl 2 "No", modify
lab def in_18yo_lbl 1 "Yes", modify
lab def ex_strke_lbl 2 "No", modify
lab def ex_strke_lbl 1 "Yes", modify
lab def ex_recnt_lbl 2 "No", modify
lab def ex_recnt_lbl 1 "Yes", modify
lab def ex_preg_lbl 2 "No", modify
lab def ex_preg_lbl 1 "Yes", modify
lab def ex_ogtt_lbl 2 "No", modify
lab def ex_ogtt_lbl 1 "Yes", modify
lab def ex_mentl_lbl 2 "No", modify
lab def ex_mentl_lbl 1 "Yes", modify
lab def ex_hep_lbl 2 "No", modify
lab def ex_evinf_lbl 1 "Yes", modify
lab def ex_hep_lbl 1 "Yes", modify
lab val ex_mentl ex_mentl_lbl
lab val ex_evinf ex_evinf_lbl
lab val ex_hep ex_hep_lbl
lab val inex_elig inex_elig_lbl
lab val in_t2mel in_t2mel_lbl
lab val in_ic in_ic_lbl
lab val in_heac1 in_heac1_lbl
lab val in_fplgl in_fplgl_lbl
lab val in_fleng in_fleng_lbl
lab val in_cmssr in_cmssr_lbl
lab val in_18yo in_18yo_lbl
lab val ex_strke ex_strke_lbl
lab val ex_recnt ex_recnt_lbl
lab val ex_preg ex_preg_lbl
lab val ex_ogtt ex_ogtt_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_inclu_eligibility.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_calc_grid `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var cal4gr2 "Group example (value)"
lab var cal3gr1 "Group example (name)"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_calc_grid.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_calculations `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var cal2val2 "Value 2"
lab var cal1val1 "Value 1"
lab var cal6avg "Average of group example values"
lab var cal7val4 "Value 3"
lab var cal8sd "Square root of value"
lab var cal5sum "Sum of Value 1 + Value 2"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_calculations.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_discrepancynote `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var dn2date "Example: Provide the date if the exam was completed or if the exam is in progress."
lab var dn1exam "Example: Status of a physical exam"
lab def dn1exam_lbl 2 "In Progess", modify
lab def dn1exam_lbl 1 "Completed", modify
lab def dn1exam_lbl 4 "Not Completed", modify
lab def dn1exam_lbl 3 "On Hold", modify
lab val dn1exam dn1exam_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_discrepancynote.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_emailaction `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var eml1smt "Example: Submit for review"
lab def eml1smt_lbl 2 "No", modify
lab def eml1smt_lbl 1 "Yes", modify
lab val eml1smt eml1smt_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_emailaction.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_insertaction `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var si2measr "Example: BP & HR measures"
lab var si3vals "Example: BP & HR values"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_insertaction.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_itemoptions `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var itm5hide2_3 "Item that is hidden and required"
lab var itm7decw "Item that allows 2 decimal places"
lab var itm6int "Integer item"
lab var itm5hide2_2 "Item that is hidden and required"
lab var itm5hide2_1 "Item that is hidden and required"
lab var itm5hide2 "Item that is hidden and required"
lab var itm4hide "Item that is hidden"
lab var itm3show "Item that is shown"
lab var itm2req "Item that is required"
lab var itm1nr "Item that is not required"
lab var itm5show2 "Item that is shown"
lab def itm1nr_lbl 1 "Yes", modify
lab def itm1nr_lbl 2 "No", modify
lab def itm2req_lbl 1 "Yes", modify
lab def itm2req_lbl 2 "No", modify
lab def itm3show_lbl 1 "Yes", modify
lab def itm3show_lbl 2 "No", modify
lab def itm5show2_lbl 1 "Yes", modify
lab def itm5show2_lbl 2 "No", modify
lab val itm1nr itm1nr_lbl
lab val itm5show2 itm5show2_lbl
lab val itm3show itm3show_lbl
lab val itm2req itm2req_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_itemoptions.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_layouts `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var lay10cb2_7 "Vertical Checkbox"
lab var lay10cb2_6 "Vertical Checkbox"
lab var lay10cb2_5 "Vertical Checkbox"
lab var lay10cb2_4 "Vertical Checkbox"
lab var lay10cb2_3 "Vertical Checkbox"
lab var lay10cb2_2 "Vertical Checkbox"
lab var lay10cb2_1 "Vertical Checkbox"
lab var lay10cb2 "Vertical Checkbox"
lab var lay4col1 "Example: Column 1"
lab var lay3col3 "Example: Column 3"
lab var lay2col2 "Example: Column 2"
lab var lay1col1 "Example: Column 1"
lab var lay10cb2_8 "Vertical Checkbox"
lab var lay9cb1_7 "Horizontal Checkbox"
lab var lay9cb1_6 "Horizontal Checkbox"
lab var lay9cb1_5 "Horizontal Checkbox"
lab var lay9cb1_4 "Horizontal Checkbox"
lab var lay9cb1_3 "Horizontal Checkbox"
lab var lay9cb1_2 "Horizontal Checkbox"
lab var lay9cb1_1 "Horizontal Checkbox"
lab var lay9cb1 "Horizontal Checkbox"
lab var lay8col3 "Example: Column 3"
lab var lay8col2 "Example: Column 2"
lab var lay7col1 "Example: Column 1"
lab var lay6col3 "Example: Column 3"
lab var lay5col2 "Example: Column 2"
lab var lay9cb1_8 "Horizontal Checkbox"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_layouts.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_layouts_grid `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var lay11gr1 "Repeating Group/Grid Column 1"
lab var lay12gr2 "Repeating Group/Grid Column 2"
lab var lay13gr3 "Repeating Group/Grid Column 3"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_layouts_grid.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_responseoptions `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var res4ms "Multi-select Option"
lab var res9fle "File Upload Option"
lab var res8pdt "Partial Date Option"
lab var res7dt "Date Option"
lab var res6rd "Radio Button Option"
lab var res5chk_4 "Checkbox Option"
lab var res5chk_3 "Checkbox Option"
lab var res5chk_2 "Checkbox Option"
lab var res5chk_1 "Checkbox Option"
lab var res5chk "Checkbox Option"
lab var res4ms_4 "Multi-select Option"
lab var res4ms_3 "Multi-select Option"
lab var res4ms_2 "Multi-select Option"
lab var res4ms_1 "Multi-select Option"
lab var res3ss "Single-select Option"
lab var res2ta "Text Area Option"
lab var res1txt "Text Option"
lab var res10sld "Scale Option"
lab def res3ss_lbl 2 "Option 2: Eyes", modify
lab def res6rd_lbl 3 "Craniofacial", modify
lab def res6rd_lbl 2 "Eyes", modify
lab def res3ss_lbl 3 "Option 3: Carniofacial", modify
lab def res3ss_lbl 1 "Option 1: Ear,Nose,Throat", modify
lab def res6rd_lbl 4 "Other", modify
lab def res6rd_lbl 1 "Ear,Nose,Throat", modify
lab val res3ss res3ss_lbl
lab val res6rd res6rd_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_responseoptions.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_showaction `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var si1bphr "Example: BP & HR measurements status"
lab def si1bphr_lbl 1 "Yes", modify
lab def si1bphr_lbl 2 "No", modify
lab val si1bphr si1bphr_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_showaction.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_texttypes `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var txt5lgo "Show use of Image"
lab var txt3url "Show URL Option"
lab var txt4sml "Smaller text area"
lab var txt2fmt "Define different text formats using HTML"
lab var txt1def "Define standard test types"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_texttypes.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_kitch_validations `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var val10rx3 "Validation: Require Date in January"
lab var val5ne "Validation: Not equal to function"
lab var val6eq "Validation: Equal to function"
lab var val7rng "Validation: Range function"
lab var val9rx2 "Validation: Regexp: number format"
lab var val8rx1 "Validation: Regexp: 3 Letters"
lab var val4lte "Validation: Less than or equal to function"
lab var val3gte "Validation: Greater than or equal to function"
lab var val2lt "Validation: Less than function"
lab var val1gt "Validation: Greater than function"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_kitch_validations.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_local_tests `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var rbc_units "RBC Units"
lab var site_ab "Indicate Site"
lab var site_dec "Site Name"
lab var ur_dt "Date Urinalysis"
lab var ur_leuk "Leukocytes results"
lab var ur_nitr "Nitrites results"
lab var ur_pro "Protein results"
lab var wbc_units "WBC Units"
lab var alb_units "Albumin Units"
lab var cal_units "Calcium Units"
lab var ch_alb "Albumin results"
lab var ch_cal "Calcium results"
lab var ch_dt "Date chemistry tests"
lab var ch_pot "Potassium results"
lab var hem_dt "Date hematology tests"
lab var hem_hem "Hemoglobin results"
lab var rhe_units "Rhe Factor Units"
lab var hem_rbc "RBC results"
lab var hem_rhe "Rheumatoid Factor results"
lab var hem_units "Hemoglobin Units"
lab var hem_wbc "WBC results"
lab var pot_units "Potassium Units"
lab def ur_pro_lbl 2 "2+", modify
lab def ur_nitr_lbl 1 "Positive", modify
lab def ur_nitr_lbl 0 "Negative", modify
lab def ur_pro_lbl 0 "Negative", modify
lab def ur_pro_lbl 4 "4+", modify
lab def ur_leuk_lbl 0 "Negative", modify
lab def ur_pro_lbl 9 "Trace", modify
lab def ur_leuk_lbl 1 "Positive", modify
lab def ur_pro_lbl 1 "1+", modify
lab def ur_pro_lbl 3 "3+", modify
lab val ur_leuk ur_leuk_lbl
lab val ur_pro ur_pro_lbl
lab val ur_nitr ur_nitr_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_local_tests.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_medic_g1 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var per_comm "Comments:"
lab var per_diag "Diagnosis:"
lab var per_date "Date of Diagnosis"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_medic_g1.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_medic_g2 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var fam_comm "Comments:"
lab var fam_date "Date of Diagnosis:"
lab var fam_diag "Diagnosis:"
lab var fam_id "Family Member:"
lab def fam_id_lbl 8 "Maternal Uncle", modify
lab def fam_id_lbl 12 "Paternal Aunt", modify
lab def fam_id_lbl 11 "Paternal Uncle", modify
lab def fam_id_lbl 10 "Paternal Grandmother", modify
lab def fam_id_lbl 8 "Paternal Grandfather", modify
lab def fam_id_lbl 1 "Mother", modify
lab def fam_id_lbl 2 "Father", modify
lab def fam_id_lbl 3 "Brother", modify
lab def fam_id_lbl 4 "Sister", modify
lab def fam_id_lbl 5 "Maternal Grandfather", modify
lab def fam_id_lbl 6 "Maternal Grandmother", modify
lab def fam_id_lbl 7 "Maternal Aunt", modify
lab val fam_id fam_id_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_medic_g2.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_mri_mri `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var mri_ab "Describe Results"
lab var mri_doc "Upload MRI scan"
lab var mri_no "MRI not performed - reason"
lab var mri_res "Result of MRI"
lab var mri_yn "Was MRI performed"
lab def mri_yn_lbl 3 "N/A", modify
lab def mri_res_lbl 2 "Abnormal", modify
lab def mri_res_lbl 1 "Normal", modify
lab def mri_yn_lbl 2 "No", modify
lab def mri_yn_lbl 1 "Yes", modify
lab val mri_res mri_res_lbl
lab val mri_yn mri_yn_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_mri_mri.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_pharm_results `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var ph_s3st "Sample 1 Scheduled Time"
lab var ph_s3at "Sample 1 Actual Time"
lab var ph_s3rs "Sample 1 Results"
lab var ph_s2st "Sample 1 Scheduled Time"
lab var ph_s2rs "Sample 1 Results"
lab var ph_s2at "Sample 1 Actual Time"
lab var ph_s4rs "Sample 1 Results"
lab var ph_s4st "Sample 1 Scheduled Time"
lab var ph_s1st "Sample 1 Scheduled Time"
lab var ph_s1rs "Sample 1 Results"
lab var ph_s1at "Sample 1 Actual Time"
lab var ph_dt "Test Date"
lab var ph_s4at "Sample 1 Actual Time"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_pharm_results.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_physi_otherbodysystemsite `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var otherbodysystem "Other Body System/Site Description"
lab var otherbodysystem_status "Other Body System/Site Status"
lab var otherbodysystem_comments "Other Body System/Site Comments"
lab def otherbodysystem_status_lbl 1 "Normal", modify
lab def otherbodysystem_status_lbl 2 "Abnormal", modify
lab val otherbodysystem_status otherbodysystem_status_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_physi_otherbodysystemsite.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_physi_physical `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var pedate "Date"
lab var pedesc "Description"
lab var petime "Time of Day"
lab var peintensity "Intensity Level"
lab var peduration "Duration of Activity"
lab def peintensity_lbl 3 "Vigorous", modify
lab def petime_lbl 3 "Afternoon", modify
lab def petime_lbl 1 "Morning", modify
lab def petime_lbl 2 "Mid-day", modify
lab def petime_lbl 4 "Evening", modify
lab def peintensity_lbl 1 "Light", modify
lab def peintensity_lbl 2 "Moderate", modify
lab val peintensity peintensity_lbl
lab val petime petime_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_physi_physical.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_physi_ungrouped `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var appearance "Appearance"
lab var abdomen_comments "Abdomen Comments"
lab var abdomen "Abdomen"
lab var breasts_comments "Breasts Comments"
lab var chest "Chest"
lab var chest_comments "Chest Comments"
lab var diastolic "Diastolic"
lab var genitalia "Genitalia"
lab var genitalia_comments "Genitalia Comments"
lab var height "Height"
lab var heent_comments "H/E/E/N/T Comments"
lab var heent "H/E/E/N/T"
lab var heart_comments "Heart Comments"
lab var lungs "Lungs"
lab var lungs_comments "Lungs Comments"
lab var lymphnodes "Lymph Nodes"
lab var lymphnodes_comments "Lymph Nodes Comments"
lab var musculoskeletal "Musculoskeletal"
lab var musculoskeletal_comments "Musculoskeletal Comments"
lab var neurological "Neurological"
lab var neurological_comments "Neurological Comments"
lab var systolic "Systolic"
lab var weight "Weight"
lab var pedat "Date of Physical Exam"
lab var vascular_comments "Vascular Comments"
lab var vascular "Vascular"
lab var thyroid_comments "Thyroid Comments"
lab var thyroid "Thyroid"
lab var pelvis "Pelvis"
lab var pelvis_comments "Pelvis Comments"
lab var petim "Time of Physical Exam"
lab var temperature "Temperature"
lab var prostate "Prostate"
lab var prostate_comments "Prostate Comments"
lab var pulse "Pulse Rate"
lab var rectal "Rectal"
lab var rectal_comments "Rectal Comments"
lab var respiration "Respiration Rate"
lab var skin "Skin"
lab var heart "Heart"
lab var skin_comments "Skin Comments"
lab var breast "Breasts"
lab var bmi "Body Mass Index"
lab var appearance_comments "Appearance Comments"
lab def thyroid_lbl 99 "Not Examined", modify
lab def abdomen_lbl 1 "Normal", modify
lab def abdomen_lbl 2 "Abnormal", modify
lab def abdomen_lbl 99 "Not Examined", modify
lab def appearance_lbl 1 "Normal", modify
lab def appearance_lbl 2 "Abnormal", modify
lab def appearance_lbl 99 "Not Examined", modify
lab def breast_lbl 1 "Normal", modify
lab def breast_lbl 2 "Abnormal", modify
lab def breast_lbl 99 "Not Examined", modify
lab def chest_lbl 1 "Normal", modify
lab def chest_lbl 2 "Abnormal", modify
lab def chest_lbl 99 "Not Examined", modify
lab def genitalia_lbl 1 "Normal", modify
lab def genitalia_lbl 2 "Abnormal", modify
lab def genitalia_lbl 99 "Not Examined", modify
lab def heart_lbl 1 "Normal", modify
lab def heart_lbl 2 "Abnormal", modify
lab def heart_lbl 99 "Not Examined", modify
lab def heent_lbl 1 "Normal", modify
lab def heent_lbl 2 "Abnormal", modify
lab def heent_lbl 99 "Not Examined", modify
lab def lungs_lbl 1 "Normal", modify
lab def lungs_lbl 2 "Abnormal", modify
lab def lungs_lbl 99 "Not Examined", modify
lab def lymphnodes_lbl 1 "Normal", modify
lab def lymphnodes_lbl 2 "Abnormal", modify
lab def lymphnodes_lbl 99 "Not Examined", modify
lab def musculoskeletal_lbl 1 "Normal", modify
lab def musculoskeletal_lbl 2 "Abnormal", modify
lab def musculoskeletal_lbl 99 "Not Examined", modify
lab def neurological_lbl 1 "Normal", modify
lab def neurological_lbl 2 "Abnormal", modify
lab def neurological_lbl 99 "Not Examined", modify
lab def pelvis_lbl 1 "Normal", modify
lab def pelvis_lbl 2 "Abnormal", modify
lab def pelvis_lbl 99 "Not Examined", modify
lab def prostate_lbl 1 "Normal", modify
lab def prostate_lbl 2 "Abnormal", modify
lab def prostate_lbl 99 "Not Examined", modify
lab def rectal_lbl 1 "Normal", modify
lab def rectal_lbl 2 "Abnormal", modify
lab def rectal_lbl 99 "Not Examined", modify
lab def skin_lbl 1 "Normal", modify
lab def skin_lbl 2 "Abnormal", modify
lab def skin_lbl 99 "Not Examined", modify
lab def thyroid_lbl 1 "Normal", modify
lab def thyroid_lbl 2 "Abnormal", modify
lab def vascular_lbl 1 "Normal", modify
lab def vascular_lbl 2 "Abnormal", modify
lab def vascular_lbl 99 "Not Examined", modify
lab val abdomen abdomen_lbl
lab val heart heart_lbl
lab val genitalia genitalia_lbl
lab val chest chest_lbl
lab val breast breast_lbl
lab val appearance appearance_lbl
lab val vascular vascular_lbl
lab val thyroid thyroid_lbl
lab val skin skin_lbl
lab val rectal rectal_lbl
lab val prostate prostate_lbl
lab val pelvis pelvis_lbl
lab val neurological neurological_lbl
lab val musculoskeletal musculoskeletal_lbl
lab val lymphnodes lymphnodes_lbl
lab val lungs lungs_lbl
lab val heent heent_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_physi_ungrouped.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_promi_promis `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var fatexp21 "Bathe or shower"
lab var fatexp5 "Extreme exhaustion"
lab var fatexp40 "Exercise"
lab var fatexp33 "Limit work"
lab var fatexp30 "Thinking clearly"
lab var fatexp20 "Tired"
lab var fatexp18 "Run out of energy"
lab def fatexp33_lbl 0 "Never", modify
lab def fatexp18_lbl 0 "Never", modify
lab def fatexp18_lbl 1 "Rarely", modify
lab def fatexp18_lbl 2 "Sometimes", modify
lab def fatexp18_lbl 3 "Often", modify
lab def fatexp18_lbl 4 "Always", modify
lab def fatexp20_lbl 0 "Never", modify
lab def fatexp20_lbl 1 "Rarely", modify
lab def fatexp20_lbl 2 "Sometimes", modify
lab def fatexp20_lbl 3 "Often", modify
lab def fatexp20_lbl 4 "Always", modify
lab def fatexp21_lbl 0 "Never", modify
lab def fatexp21_lbl 1 "Rarely", modify
lab def fatexp21_lbl 2 "Sometimes", modify
lab def fatexp21_lbl 3 "Often", modify
lab def fatexp21_lbl 4 "Always", modify
lab def fatexp30_lbl 0 "Never", modify
lab def fatexp30_lbl 1 "Rarely", modify
lab def fatexp30_lbl 2 "Sometimes", modify
lab def fatexp30_lbl 3 "Often", modify
lab def fatexp30_lbl 4 "Always", modify
lab def fatexp5_lbl 4 "Always", modify
lab def fatexp5_lbl 3 "Often", modify
lab def fatexp5_lbl 2 "Sometimes", modify
lab def fatexp5_lbl 1 "Rarely", modify
lab def fatexp5_lbl 0 "Never", modify
lab def fatexp40_lbl 4 "Always", modify
lab def fatexp40_lbl 3 "Often", modify
lab def fatexp40_lbl 2 "Sometimes", modify
lab def fatexp40_lbl 1 "Rarely", modify
lab def fatexp40_lbl 0 "Never", modify
lab def fatexp33_lbl 4 "Always", modify
lab def fatexp33_lbl 3 "Often", modify
lab def fatexp33_lbl 2 "Sometimes", modify
lab def fatexp33_lbl 1 "Rarely", modify
lab val fatexp33 fatexp33_lbl
lab val fatexp18 fatexp18_lbl
lab val fatexp20 fatexp20_lbl
lab val fatexp21 fatexp21_lbl
lab val fatexp30 fatexp30_lbl
lab val fatexp40 fatexp40_lbl
lab val fatexp5 fatexp5_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_promi_promis.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_proto_protocoldeviationlog `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var pd_event "Event deviation occurred"
lab var pd_dev "Description of deviation"
lab var pd_prodev "Procedure deviation occurred"
lab var pd_comm "Comments"
lab var pd_rea "Reason for deviation"
lab def pd_prodev_lbl 6 "Local Lab", modify
lab def pd_prodev_lbl 4 "Pharmacokinetics", modify
lab def pd_prodev_lbl 5 "Vital Signs", modify
lab def pd_prodev_lbl 2 "Neurological Exam", modify
lab def pd_prodev_lbl 1 "Inclusion/Exclusion", modify
lab def pd_prodev_lbl 7 "Physical Exam", modify
lab def pd_event_lbl 4 "Monthly Follow Up", modify
lab def pd_event_lbl 3 "2-week Follow Up", modify
lab def pd_event_lbl 2 "1-week Follow Up", modify
lab def pd_event_lbl 1 "First Visit", modify
lab def pd_prodev_lbl 3 "MRI", modify
lab val pd_prodev pd_prodev_lbl
lab val pd_event pd_event_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_proto_protocoldeviationlog.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_serio_sae1 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sae2_yn "Add SAE"
lab var sae1_cat "SAE Category"
lab var sae1_con "Continuing SAE"
lab var sae1_des "Description of SAE"
lab var sae1_dted "Date of end of SAE"
lab var sae1_dtst "Date of start of SAE"
lab var sae1_ot "Other category"
lab var sae1_stat "Participant still in study?"
lab var sae1_yn "Did SAE occur?"
lab def sae1_cat_lbl 4 "Disability", modify
lab def sae1_cat_lbl 5 "Other", modify
lab def sae1_con_lbl 1 "Yes", modify
lab def sae1_cat_lbl 3 "Prolonged hospitalization", modify
lab def sae1_cat_lbl 2 "Life-threatening", modify
lab def sae2_yn_lbl 2 "No", modify
lab def sae2_yn_lbl 1 "Yes", modify
lab def sae1_yn_lbl 2 "No", modify
lab def sae1_yn_lbl 1 "Yes", modify
lab def sae1_cat_lbl 1 "Death", modify
lab def sae1_stat_lbl 2 "No", modify
lab def sae1_stat_lbl 1 "Yes", modify
lab def sae1_con_lbl 2 "No", modify
lab val sae2_yn sae2_yn_lbl
lab val sae1_cat sae1_cat_lbl
lab val sae1_con sae1_con_lbl
lab val sae1_stat sae1_stat_lbl
lab val sae1_yn sae1_yn_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_serio_sae1.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_serio_sae2 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sae2_con "Continuing SAE"
lab var sae2_des "Description of SAE"
lab var sae3_yn "Add SAE"
lab var sae2_dted "Date of end of SAE"
lab var sae2_dtst "Date of start of SAE"
lab var sae2_ot "Other category"
lab var sae2_stat "Participant still in study?"
lab var sae2_cat "SAE Category"
lab def sae2_con_lbl 1 "Yes", modify
lab def sae3_yn_lbl 1 "Yes", modify
lab def sae3_yn_lbl 2 "No", modify
lab def sae2_stat_lbl 2 "No", modify
lab def sae2_stat_lbl 1 "Yes", modify
lab def sae2_con_lbl 2 "No", modify
lab def sae2_cat_lbl 1 "Death", modify
lab def sae2_cat_lbl 2 "Life-threatening", modify
lab def sae2_cat_lbl 3 "Prolonged hospitalization", modify
lab def sae2_cat_lbl 4 "Disability", modify
lab def sae2_cat_lbl 5 "Other", modify
lab val sae3_yn sae3_yn_lbl
lab val sae2_stat sae2_stat_lbl
lab val sae2_con sae2_con_lbl
lab val sae2_cat sae2_cat_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_serio_sae2.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_serio_sae3 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sae3_des "Description of SAE"
lab var sae3_cat "SAE Category"
lab var sae3_stat "Participant still in study?"
lab var sae4_yn "Add SAE"
lab var sae3_ot "Other category"
lab var sae3_dtst "Date of start of SAE"
lab var sae3_dted "Date of end of SAE"
lab var sae3_con "Continuing SAE"
lab def sae3_stat_lbl 2 "No", modify
lab def sae4_yn_lbl 1 "Yes", modify
lab def sae3_cat_lbl 1 "Death", modify
lab def sae3_cat_lbl 2 "Life-threatening", modify
lab def sae3_cat_lbl 3 "Prolonged hospitalization", modify
lab def sae3_cat_lbl 4 "Disability", modify
lab def sae3_cat_lbl 5 "Other", modify
lab def sae3_con_lbl 1 "Yes", modify
lab def sae3_con_lbl 2 "No", modify
lab def sae3_stat_lbl 1 "Yes", modify
lab def sae4_yn_lbl 2 "No", modify
lab val sae4_yn sae4_yn_lbl
lab val sae3_cat sae3_cat_lbl
lab val sae3_con sae3_con_lbl
lab val sae3_stat sae3_stat_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_serio_sae3.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_serio_sae4 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sae4_stat "Participant still in study?"
lab var sae4_cat "SAE Category"
lab var sae4_con "Continuing SAE"
lab var sae4_des "Description of SAE"
lab var sae4_dted "Date of end of SAE"
lab var sae4_dtst "Date of start of SAE"
lab var sae4_ot "Other category"
lab var sae5_yn "Add SAE"
lab def sae5_yn_lbl 1 "Yes", modify
lab def sae4_stat_lbl 2 "No", modify
lab def sae4_cat_lbl 1 "Death", modify
lab def sae4_cat_lbl 2 "Life-threatening", modify
lab def sae4_cat_lbl 3 "Prolonged hospitalization", modify
lab def sae5_yn_lbl 2 "No", modify
lab def sae4_cat_lbl 5 "Other", modify
lab def sae4_cat_lbl 4 "Disability", modify
lab def sae4_stat_lbl 1 "Yes", modify
lab def sae4_con_lbl 2 "No", modify
lab def sae4_con_lbl 1 "Yes", modify
lab val sae4_stat sae4_stat_lbl
lab val sae4_con sae4_con_lbl
lab val sae4_cat sae4_cat_lbl
lab val sae5_yn sae5_yn_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_serio_sae4.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_serio_sae5 `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var sae5_stat "Participant still in study?"
lab var sae5_ot "Other category"
lab var sae5_con "Continuing SAE"
lab var sae5_dtst "Date of start of SAE"
lab var sae5_dted "Date of end of SAE"
lab var sae5_des "Description of SAE"
lab var sae5_cat "SAE Category"
lab def sae5_stat_lbl 1 "Yes", modify
lab def sae5_stat_lbl 2 "No", modify
lab def sae5_con_lbl 2 "No", modify
lab def sae5_con_lbl 1 "Yes", modify
lab def sae5_cat_lbl 5 "Other", modify
lab def sae5_cat_lbl 4 "Disability", modify
lab def sae5_cat_lbl 3 "Prolonged hospitalization", modify
lab def sae5_cat_lbl 2 "Life-threatening", modify
lab def sae5_cat_lbl 1 "Death", modify
lab val sae5_stat sae5_stat_lbl
lab val sae5_cat sae5_cat_lbl
lab val sae5_con sae5_con_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_serio_sae5.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_verif_verify `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var veri_init "Verification Affirmation Initials"
lab var eligibility_conf "Affirmation that a signed informed consent exists"
lab var veri_date "Date"
lab def eligibility_conf_lbl 0 "No", modify
lab def eligibility_conf_lbl 1 "Yes", modify
lab val eligibility_conf eligibility_conf_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_verif_verify.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_vital_bplog `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var vs_hr "Heart Rate"
lab var vs_sysbp "Systolic BP"
lab var vs_diabp "Diastolic BP"
lab var vs_type "Supine or Standing Position"
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_vital_bplog.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.av_ig_vital_vitals `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
lab var vs_avsys "Average Systolic BP"
lab var vs_bmi "Calculated BMI"
lab var vs_avdia "Average Diastolic BP"
lab var vs_avhr "Average Heart Rate"
lab var vs_temp "Temperature"
lab var vs_tunit "Units (C or F)"
lab var vs_bphr "Status of BP and HR exam"
lab var vs_comm "Comments"
lab var vs_hght "Height"
lab var vs_units "Units"
lab var vs_wght "Weight"
lab def vs_bphr_lbl 2 "No", modify
lab def vs_units_lbl 2 "cm/kg", modify
lab def vs_units_lbl 1 "lbs/inches", modify
lab def vs_tunit_lbl 2 "Fahrenheit", modify
lab def vs_tunit_lbl 1 "Celsius", modify
lab def vs_bphr_lbl 1 "Yes", modify
lab val vs_units vs_units_lbl
lab val vs_bphr vs_bphr_lbl
lab val vs_tunit vs_tunit_lbl
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/ig_vital_vitals.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.metadata_crf_ig_item `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/metadata_crf_ig_item.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.metadata_event_crf_ig `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/metadata_event_crf_ig.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.response_set_labels `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/response_set_labels.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.subject_groups `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/subject_groups.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.subjects `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/subjects.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.timestamp_data `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/timestamp_data.dta"
clear
odbc load, exec("SELECT * FROM the_juno_diabetes_study.timestamp_schema `data_filter_string'") connectionstring("`odbc_string_or_file_dsn_path'")
quietly ds, has(type string)
quietly format `r(varlist)' %20s
save "`snapshotdir'/timestamp_schema.dta"
clear
