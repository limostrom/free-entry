/*

call_sod_merge.do

Merge bank names from SOD

*/

pause on

global cr_dir "/Volumes/Seagate Por/Call Reports"
global proj_dir "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism"
	cap mkdir "$proj_dir/processed-data/calls/"
cd "$cr_dir"


forval y = 2001/2022 {
	
	import delimited "$proj_dir/raw-data/sod/ALL_`y'.csv", clear varn(1)
	keep year rssdid namefull
	drop if rssdid == 0
	duplicates drop
	isid rssdid
	
	tempfile names`y'
	save `names`y'', replace
	
	foreach m in "0630" "0930" "1231" "0331" {
		if "`m'" == "0331" {
			local nextyr = `y' + 1
		}
		import delimited "sched_RI/FFIEC CDR Call Schedule RI `m'`y'.txt", clear varn(1)
		keep idrssd riad4080
		lab var riad4080 "Service charges on deposit accounts - domestic offices"
		drop if strpos(riad4080,"SERV") == 1
		destring riad4080, replace
		
		ren idrssd rssdid
		
		gen monthday = `m'
		
		if "`m'" == "0630" {
			tempfile calls`y'
			save `calls`y'', replace
		}
		if inlist("`m'","0930","1231","0331") {
			append using `calls`y''
			save `calls`y'', replace
		}
		
	} // month
	
	merge m:1 rssdid using `names`y''
	
	save "$proj_dir/processed-data/calls/call_RIAD4080_sod_`y'.dta", replace
	
} // year


use "$proj_dir/processed-data/calls/call_RIAD4080_sod_2001.dta", clear

forval y = 2002/2022 {
	append using "$proj_dir/processed-data/calls/call_RIAD4080_sod_`y'.dta"
}

gen quarter = 1 if monthday == 331
	replace quarter = 2 if monthday == 630
	replace quarter = 3 if monthday == 930
	replace quarter = 4 if monthday == 1231
	
sort namefull year quarter
