/*


ivregs_bystate.do

HP filtered in R but need to lag in Stata


*/
clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

* State FIPS -> Abbreviation xwalk
import delimited "states.csv", clear varn(1)
tempfile st
save `st', replace

* Naics names
import delimited "naics2.csv", clear varn(1)
tempfile inds
save `inds', replace

* Start w/ RHS: WAP and the instrument
import delimited "rhs_bystate.csv", clear varn(1)
ren year merge_year
merge 1:1 statefips merge_year using "birth_iv_bystate.dta", nogen keep(1 3)
ren merge_year year
xtset statefips year

gen dln_wap = ln(wap) - ln(L.wap)
gen dln_wap_hp = ln(wap_hp) - ln(L.wap_hp)

foreach var of varlist l20* {
	replace `var' = ""  if `var' == "NA"
	destring `var', replace
}

ren births l20_births
gen l20_birthrate = l20_births / l20_pop
gen l20_sh_under5 = l20_pop_under5 / l20_pop
gen l20_sh_under5_hp = l20_pop_under5_hp / l20_pop_hp
gen l20_d_sh_under5 = l20_sh_under5 - l.l20_sh_under5
gen l20_d_sh_under5_hp = l20_sh_under5_hp - l.l20_sh_under5_hp

tempfile rhs
save `rhs', replace

*merge 1:1 statefips year using "deposits_state.dta", nogen
*reg depsumbr l20_sh_under5_hp 


* Now load in LHS: BDS and DataAxle Startup Rates
import delimited "lhs_bystate.csv", clear varn(1)
local varlist bds_sr axle_age0 axle_tot axle_tot_hp axle_age0_hp axle_sr axle_sr_hp

foreach var of local varlist {
	replace `var' = "" if `var' == "NA"
}
destring `varlist', replace

merge m:1 statefips year using `rhs'

export delimited "regs_full.csv", replace

preserve //--- First Differences by Sector for Rolling Regs ---
	drop if naics2 == ""
	egen stateXsector = group(statefips naics2)
	xtset stateXsector year
		
	gen sr = bds_age0_hp / bds_tot_hp
	gen sr_fd = sr - l.sr
	gen wapgr_fd = dln_wap_hp - l.dln_wap_hp
	
	export delimited "regs_full_fd.csv", replace
restore

collapse (sum) bds_age0_hp bds_tot_hp (last) dln_wap_hp, by(statefips year)
xtset statefips year
gen sr = bds_age0_hp / bds_tot_hp
gen sr_fd = sr - l.sr
gen wapgr_fd = dln_wap_hp - l.dln_wap_hp

export delimited "regs_agg_fd.csv", replace

import delimited "regs_full.csv", clear varn(1)

* 0. Long First Difference Regressions -----------------------------------------
preserve
	drop if bds_tot_hp == .
	collapse (sum) bds_tot_hp bds_age0_hp (last) dln_wap_hp, by(statefips year)
	gen bds_sr_hp = bds_age0_hp / bds_tot_hp
	keep if year <= 2007
	gen decade = int(year/10) * 10
	keep if inlist(decade, 1980, 2000)
	collapse (mean) bds_sr_hp dln_wap_hp, by(statefips decade)
	reshape wide bds_sr_hp dln_wap_hp, i(statefips) j(decade)
	drop if statefips == 72
	merge 1:1 statefips using `st', nogen assert(3)

	gen change_bds_sr = (bds_sr_hp2000 - bds_sr_hp1980) * 100
	gen change_wap_gr = (dln_wap_hp2000 - dln_wap_hp1980) * 100
	
	reg change_bds_sr change_wap_gr, robust
	gen quadrant4 = (change_wap_gr > 0) & (change_bds_sr < 0)
	export delimited statefips state quadrant4 using "quad4_states.csv", replace
	* robust to excluding AK, NH, VT, and UT
	
	#delimit ;
	tw (lfit change_bds_sr change_wap_gr, lc(eltblue) lp(l))
	   (scatter change_bds_sr change_wap_gr, mc(edkblue) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Long First-Difference by State")
	  subti("(1980s Avg to 2000s Avg)") xti("Change in WAP Growth Rate (% pts)")
	  yti("Change in Startup Rate (% pts)") legend(off)
	  xline(0,lc(gs14) lp(_)) yline(0,lc(gs14) lp(_));
	#delimit cr
	
	graph export "../output/figures/scatter_long1stdiff_80-07.pdf", replace as(pdf)
restore
preserve
	drop if bds_tot_hp == .
	collapse (sum) bds_tot_hp bds_age0_hp (last) dln_wap_hp, by(statefips year)
	gen bds_sr_hp = bds_age0_hp / bds_tot_hp
	keep if inrange(year, 2000, 2005) | inrange(year, 2015, 2019)
	gen decade = int(year/10) * 10
	collapse (mean) bds_sr_hp dln_wap_hp, by(statefips decade)
	reshape wide bds_sr_hp dln_wap_hp, i(statefips) j(decade)
	drop if statefips == 72
	merge 1:1 statefips using `st', nogen assert(3)

	gen change_bds_sr = bds_sr_hp2010 - bds_sr_hp2000
	gen change_wap_gr = dln_wap_hp2010 - dln_wap_hp2000
	
	reg change_bds_sr change_wap_gr, robust
	
	
	#delimit ;
	tw (lfit change_bds_sr change_wap_gr, lc(eltblue) lp(l))
	   (scatter change_bds_sr change_wap_gr, mc(edkblue) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Long First-Difference by State")
	  subti("(2000-2005 Avg to 2015-2019 Avg)") xti("Change in WAP Growth Rate")
	  yti("Change in Startup Rate") legend(off)
	  xline(0,lc(gs14) lp(_)) yline(0,lc(gs14) lp(_));
	#delimit cr
	
	graph export "../output/figures/scatter_long1stdiff_00-19.pdf", replace as(pdf)
	
	
restore

preserve //  By Industry 
	drop if naics2 == ""
	merge m:1 naics2 using `inds', nogen keep(1 3)
	collapse (sum) bds_tot_hp bds_age0_hp (last) dln_wap_hp, ///
		by(statefips naics2 naics2short year)
	gen bds_sr_hp = bds_age0_hp / bds_tot_hp
	keep if year <= 2007
	gen decade = int(year/10) * 10
	keep if inlist(decade, 1980, 2000)
	collapse (mean) bds_sr_hp dln_wap_hp, by(statefips naics2 naics2short decade)
	reshape wide bds_sr_hp dln_wap_hp, i(statefips naics2 naics2short) j(decade)
	
	merge m:1 statefips using `st', nogen assert(3)

	gen change_bds_sr = bds_sr_hp2000 - bds_sr_hp1980
	gen change_wap_gr = dln_wap_hp2000 - dln_wap_hp1980
	
	
	levelsof naics2, local(indlist)
	foreach i of local indlist {
		reg change_bds_sr change_wap_gr if naics2 == "`i'", robust
		
		#delimit ;
		tw (lfit change_bds_sr change_wap_gr if naics2 == "`i'", lc(eltblue) lp(l))
		   (scatter change_bds_sr change_wap_gr if naics2 == "`i'", mc(edkblue) msym("Oh")
							mlab(state) mlabsize(vsmall) mlabc(edkblue)),
		  ti("Long First-Difference by State" "`i'")
		  subti("(1980s Avg to 2000s Avg)") xti("Change in WAP Growth Rate")
		  yti("Change in Startup Rate") legend(off)
		  xline(0,lc(gs14) lp(_)) yline(0,lc(gs14) lp(_));
		#delimit cr
		
		dis `i'
		graph export "../output/figures/scatter_long1stdiff-`i'.png", replace as(png)
	}
	
	
	
restore


* 1. Run regressions by industry -----------------------------------------------
est clear
levelsof naics2, local(inds)

// Loop over industries and run xtivreg
foreach i of local inds {
	local indabbr = substr("`i'",1,2)
	dis "Sector: `i'"
	preserve
		keep if naics2 == "`i'"
		xtset statefips year
		eststo fe`indabbr': reghdfe bds_sr_hp dln_wap_hp if year <= 2007, a(statefips year) ///
			cluster(statefips year)
		eststo iv`indabbr': xtivreg bds_sr_hp (dln_wap_hp = l20_sh_under5_hp) if year <= 2007, ///
			fe vce(robust) first
			pause
	restore
}
* Save coefficients and standard errors to a file
esttab fe* iv* using "../output/tables/regs_out.csv", ///
	cells(coef se) noobs nonumbers replace


* 2. Run regressions for overall startup rate instead of industry sr -----------
preserve

	collapse (sum) bds_age0_hp bds_tot_hp axle_age0_hp axle_tot_hp ///
			 (first) dln_wap dln_wap_hp l20_birthrate l20_sh_under5_hp l20_d_sh_under5_hp, by(statefips year)
	xtset statefips year
	gen axle_sr_hp = axle_age0_hp/axle_tot_hp
	gen bds_sr_hp = bds_age0_hp/bds_tot_hp
	
	* First Stage
	reghdfe dln_wap_hp l20_sh_under5_hp if year <= 2007, a(statefips year) cluster(statefips year)
	reghdfe dln_wap_hp l20_birthrate if year <= 2007, a(statefips year) cluster(statefips year)
	
	* OLS FE Regressions
	reghdfe bds_sr_hp dln_wap if year <= 2007, a(statefips year) cluster(statefips year)
	tab year if e(sample)
	reghdfe bds_sr_hp dln_wap if inrange(year,2008,2019), a(statefips year) cluster(statefips year)
	*reghdfe axle_sr_hp dln_wap_hp if inrange(year,2008,2019), a(statefips year) cluster(statefips year)
	
	* IV Regressions
	*ivreg2 axle_sr_hp (dln_wap_hp = l20_sh_under5_hp), cluster(year)
	xtivreg bds_sr_hp (dln_wap = l20_sh_under5) if year <= 2007, ///
			fe vce(cluster statefips) first
	xtivreg bds_sr_hp (dln_wap = l20_birthrate) if year <= 2007, ///
			fe vce(cluster statefips) first
	tab year if e(sample)
	xtivreg bds_sr_hp (dln_wap = l20_sh_under5) if inrange(year,2008,2019), ///
			fe vce(cluster statefips) first
	xtivreg bds_sr_hp (dln_wap = l20_birthrate) if inrange(year,2008,2019), ///
			fe vce(cluster statefips) first
	*xtivreg axle_sr_hp (dln_wap_hp = l20_sh_under5_hp) if inrange(year,2008,2019), ///
			fe vce(cluster statefips) first
restore



* 3. Run regressions of change in ind share on LS growth -----------------------
bys statefips year: egen bds_all = total(bds_tot_hp)
bys statefips year: egen axle_all = total(axle_tot_hp)

gen ind_sh_bds = bds_tot_hp/bds_all * 100
gen ind_sh_axle = axle_tot_hp/axle_all * 100

gen d_ind_sh_bds = ind_sh_bds - L.ind_sh_bds
gen d_ind_sh_axle = ind_sh_axle - L.ind_sh_axle

levelsof naics2, local(inds)
foreach ind of local inds {
	dis "INDUSTRY: `ind'"
	* OLS FE Regressions
	
	reghdfe d_ind_sh_bds dln_wap_hp if naics2 != "`ind'", a(statefips year) cluster(statefips year)
	
	* IV Regressions
	xtivreg dependent_variable (endogenous_variable = instrumental_variable) control_variables, fe vce(cluster(panel_variable time_variable) two)
	ivreg2 d_ind_sh_bds (dln_wap_hp = l20_sh_under5_hp) if naics2 != "`ind'", cluster(year)
}

