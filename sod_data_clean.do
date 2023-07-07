/*
Lauren Mostrom
sod_data_clean.do
*/


clear all
pause on


cap cd "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/"
cd "Second Year/Y2 Paper/Fama Seminar - CRA/raw-data"

* Unzip data downloads
/*
local zips: dir "raw-data" files "*.zip"
cd "raw-data"
foreach folder of local zips {
	unzipfile "`folder'"
}
cd ../
*/

* Drop "ALL_YEAR_[1/2].csv" files since they are not needed
/*
local filelist: dir "raw-data" files "ALL_????_?.csv"
foreach file of local filelist {
	rm "raw-data/`file'"
}
*/

* Append data files together
local i = 1
local filelist: dir "sod" files "ALL_????.csv"
foreach file of local filelist {
	import delimited "sod/`file'", clear varn(1)
	cap replace depsumbr = subinstr(depsumbr,",","",.) // destring deposits
	destring depsumbr, replace
	if `i' == 1 {
		tempfile sod
		save `sod', replace
	}
	if `i' > 1 {
		append using `sod', force
		save `sod', replace
	}
	local ++i
}
cd ../

save "processed-data/sod_full_1994-2022.dta", replace

* Pulling addresses that do not have lat/lon coordinates to put through
*	the Census Bureau API
preserve 
	keep if sims_lat == . | sims_long == .
	keep year brnum addresbr city2br stalpbr zipbr
	tostring year brnum, replace
	gen uniqueid = year + brnum
	drop year brnum
	order uniqueid addresbr city2br stalpbr zipbr // many of these are in shopping centers
	split addresbr, p(",") l(2)
	replace addresbr = addresbr1 if strpos(addresbr1,"Shop")
	forval i=1(10000)220001 {
		local j = `i' + 9999
		export delimited if inrange(_n,`i',`j') using "branch_addresses_`i'_`j'.csv", novar replace
	}
restore


rename *, lower
keep year brnum namebr stnumbr cntynumb zipbr depsumbr sims_* cert rssdid namefull rssdhcr namehcr

lab var brnum "Branch Number"
lab var namebr "Branch Name"
lab var stnumbr "State FIPS of Branch"
lab var cntynumb "County FIPS of Branch"
lab var zipbr "Zipcode of Branch" // for merging w SBA data
lab var sims_acquired_date "Date last acquired by another institution"
lab var sims_established_date "Date the branch was established"
lab var sims_latitude "Latitude"
lab var sims_longitude "Longitude"
lab var sims_projection "Projection Method"
lab var cert "Bank ID (FDIC Certificate)"
lab var rssdid "Bank ID (FRB)"
lab var namefull "Bank Name"
lab var rssdhcr "Bank Holding Company ID (FRB)"
lab var namehcr "Bank Holding Company Name"

drop if inlist(stnumbr,2,15) | stnumbr >= 60

save "processed-data/sod.dta", replace
export delimited "processed-data/sod.csv", replace

* Then run sod_merge.r to match branches with tracts
