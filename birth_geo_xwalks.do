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
	
save "../processed-data/county_cbsa_xwalk.dta", replace


**************
* Birth Data *
**************

cd "../processed-data/birth_counts"

use "counts1968.dta", clear

forval y = 1969/1988 {
	append using "counts`y'.dta"
}

preserve
	collapse (sum) births, by(L20_year merge_year statefips)
	save "../birth_iv_bystate.dta", replace
restore
sdf
ren L20_year year
merge 1:1 year countyfips using "popest_80-99.dta", keep(2 3)
	drop if inlist(year, 1980, 1981)
	// -------------------------------------------------------------------------
	// Problem: Birth counts by county are only available up through 1988;
	// for 1989-2004, they are only available for counties with a population
	// of 100k people or greater, and for 2005-Present they are not available by
	// county at all. To deal with this problem I'm instead using population
	// under 5, but will also compare the correlations for this series and the
	// birthrate series for 1982-1988 for which both are available.
	// -------------------------------------------------------------------------
ren year L20_year
	replace merge_year = L20_year + 20 if merge_year == .

ren countyfips fipscd
replace statefips = int(fipscd/1000) if statefips == .

merge m:1 fipscd using "../county_cbsa_xwalk.dta", gen(_m1) keep(1 3)
	gen nonmetro = _m1 == 1

replace cbsacode = statefips if nonmetro

* First compute total births, pop, and pop under 5 by CBSA
preserve
	keep if nonmetro == 0
	collapse (sum) births pop pop_under5, by(L20_year merge_year cbsacode nonmetro)
	assert cbsacode > 100
	tempfile metro
	save `metro', replace
restore

* Now compute and append rural (nonmetro) by state
preserve
	keep if nonmetro == 1
	collapse (sum) births pop pop_under5, by(L20_year merge_year cbsacode nonmetro)
	tempfile nonmetro
	save `nonmetro', replace
restore

use `metro', clear
append using `nonmetro'

replace births = . if births == 0

gen birthrate = births / (pop / 1000) // births per 1,000 people
gen sh_under5 = pop_under5 / pop // share of pop under 5 (alt IV)

sort cbsacode L20_year

save "birth_instrument_ts.dta", replace


