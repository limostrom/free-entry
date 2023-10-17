/*


deposits_sum.do



*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

* State FIPS -> Abbreviation xwalk
import delimited "../processed-data/states.csv", clear varn(1)
tempfile st
save `st', replace

/*
* Append annual SOD files together
local i = 1
local filelist: dir "sod" files "ALL_????.csv"
foreach file of local filelist {
	import delimited "sod/`file'", clear varn(1)
	cap replace depsumbr = subinstr(depsumbr,",","",.)
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

save "../processed-data/sod_1994-2017.dta", replace
*/

use year stalpbr depsumbr using "../processed-data/sod_1994-2017.dta", clear
ren stalpbr state
merge m:1 state using `st', nogen

collapse (sum) depsumbr, by(year statefips) fast
save "../processed-data/deposits_state.dta", replace

sdf
preserve
	collapse (sum) depsumbr, by(msabr year charter) fast
		ren msabr cbsacode
	ren depsumbr dep_
	reshape wide dep_, i(cbsacode year) j(charter) string
	ren *, lower
	gen dep_tot = dep_fed + dep_state

	save "../processed-data/deposits_cbsa.dta", replace

	ren year L20_year
	keep L20_year dep_tot cbsacode
	ren dep_tot L20_deposits
	save "../processed-data/deposits_lagged.dta", replace
restore

