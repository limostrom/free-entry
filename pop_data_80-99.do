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
ren Under5 pop_under5
keep year countyfips pop pop_under5
collapse (sum) pop pop_under5, by(year countyfips)

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
	ren v12 countyfips
	ren v13 agegrp
	ren v16 pop
	destring year countyfips agegrp pop, replace
	gen age04 = inlist(agegrp,0,1)
	bys year countyfips age04: egen popsum = total(pop)
	
	keep year countyfips age04 popsum
	duplicates drop
	reshape wide popsum, i(year countyfips) j(age04)
		gen pop = popsum0 + popsum1
		ren popsum1 pop_under5
		drop popsum0
	
	
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
	replace pop_under5 = L`i'.pop_under5 + (`i'/10) * (F`j'.pop_under5 - L`i'.pop_under5) if year == 1980 + `i'
}


save "../processed-data/birth_counts/popest_80-99.dta", replace
