/*

pop_data_80-99.do

*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

* Start with 1980s population estimates by county
import excel "intercensal_pop/pe-02.xls", clear cellra(A6:U18853) first

drop if _n == 1

ren Year year
ren FIPS countyfips
	destring countyfips, replace

egen pop = rowtotal(Under5-yearsandover)
keep year countyfips pop
collapse (sum) pop, by(year countyfips)

tempfile pop80
save `pop80', replace


* Next 1990s population estimates by county
forval y = 90/99 {
	import delimited "intercensal_pop/stch-icen19`y'.txt", clear
	replace v1 = subinstr(v1, "  ", " ", .)
	replace v1 = subinstr(v1, "   ", " ", .)
	replace v1 = subinstr(v1, "  ", " ", .)

	split v1, p(" ")
	gen year = "19" + v11
		destring year, replace
	ren v12 countyfips
		destring countyfips, replace
	ren v16 pop
		destring pop, replace
	collapse (sum) pop, by(year countyfips)
	
	tempfile pop`y'
	save `pop`y'', replace
}

* Append all together
use `pop80', clear
forval y = 90/99 {
	append using `pop`y''
}

xtset countyfips year
tsfill

* Impute 1981-1989
forval i = 1/9 {
	local j = 10-`i'
	replace pop = L`i'.pop + (`i'/10) * (F`j'.pop - L`i'.pop) if year == 1980 + `i'
	pause
}


save "../processed-data/birth_counts/popest_80-99.dta", replace
