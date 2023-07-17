/*

birth_geo_xwalks.do

*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

**************
* Crosswalks *
**************

* First import SMSA -> MSA Crosswalk
import excel "FR05_CBSA_MSA_XWALK_pub.xls", clear first case(lower)

ren newmsaif newmsa
keep oldmsa newmsa fipscd st

keep if newmsa != ""
destring fipscd, replace

replace oldmsa = subinstr(oldmsa, " L", "", .)
destring oldmsa, replace

duplicates drop

tempfile xwalk1
save `xwalk1', replace

* Then import MSA -> CBSA Crosswalk for merging with present numbers
import delimited "cbsa2fipsxw.csv", clear

keep cbsacode metrodivisioncode fipsstatecode fipscountycode
drop if fipsstatecode == .

duplicates drop
tostring fipsstatecode fipscountycode, replace
	replace fipsstatecode = "0" + fipsstatecode if strlen(fipsstatecode) == 1
	assert strlen(fipscountycode) <= 3
	replace fipscountycode = "00" + fipscountycode if strlen(fipscountycode) == 1
	replace fipscountycode = "0" + fipscountycode if strlen(fipscountycode) == 2
gen fipscd = fipsstatecode + fipscountycode
destring fipscd, replace
	drop fipsstate fipscounty
	
isid fipscd
	
tempfile xwalk2
save `xwalk2', replace


**************
* Birth Data *
**************

cd "../processed-data/birth_counts"

use "counts1985.dta", clear

forval y = 1986/1999 {
	append using "counts`y'.dta"
}

ren countyfips fipscd

merge m:1 fipscd using `xwalk2', gen(_m1)

* First compute total births by CBSA
preserve
	keep if cbsacode != .
	collapse (sum) births, by(L20_year merge_year cbsacode)
		ren births metro_births
	assert cbsacode > 100
	tempfile metro
	save `metro', replace
restore

* Now compute and append rural (nonmetro) births by state
preserve
	keep if cbsacode == .
	collapse (sum) births, by(L20_year merge_year statefips)
		ren births nonmetro_births
	ren statefips cbsacode
	tempfile nonmetro
	save `nonmetro', replace
restore

use `metro', clear
append using `nonmetro'

drop if cbsacode == . | L20_year == .

export delimited "cbsa_nmstate_ts.csv", replace


