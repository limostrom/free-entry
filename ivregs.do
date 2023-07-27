/*


ivregs.do

HP filter everything?



*/
clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

use "fulldata.dta", clear

merge m:1 cbsacode L20_year using "deposits_lagged.dta", keep(1 3) nogen
merge m:1 cbsacode year using "deposits_cbsa.dta", keep(1 3) nogen keepus(dep_tot)

xtset indXcbsa year

/* Deposits Quartiles - not needed right now
gen dep_quartile = .
gen L20_dep_percap = L20_deposits/pop
forval y = 2014/2019 {
	xtile dep_quartile`y' = L20_dep_percap if year == `y', n(4)
	replace dep_quartile = dep_quartile`y' if year == `y'
	drop dep_quartile`y'
}
*/

local varlist wap clf dep_tot /*dep_fed dep_state*/
foreach var of local varlist {
	gen dln_`var' = ln(`var') - ln(L.`var')
}
replace axle_sr = axle_sr * 100
replace bds_sr = bds_sr * 100
gen d_sh_under5 = (sh_under5 - l.sh_under5) * 100

* 1. Run regressions by industry -----------------------------------------------
levelsof naics2, local(inds)
foreach ind of local inds {
	reghdfe bds_sr dln_wap if naics2 == "`ind'", a(cbsacode year) cluster(cbsacode year)
	ivreg2 bds_sr (dln_wap = d_sh_under5), cluster(year)
}




* 2. Run regressions for overall startup rate instead of industry sr -----------
preserve
	keep cbsacode year naics2 bds_tot bds_age0 axle_tot dln_wap dln_clf axle_age0 birthrate d_sh_under5
	collapse (sum) bds_age0 bds_tot axle_age0 axle_tot ///
			 (first) dln_wap dln_clf birthrate d_sh_under5, by(cbsacode year)
	gen axle_sr = axle_age0/axle_tot
	gen bds_sr = bds_age0/bds_tot
	
	* OLS FE Regressions
	reghdfe axle_sr dln_wap, a(cbsacode year) cluster(cbsacode year)
	reghdfe bds_sr dln_wap, a(cbsacode year) cluster(cbsacode year)
	reghdfe axle_sr dln_clf, a(cbsacode year) cluster(cbsacode year)
	reghdfe bds_sr dln_clf, a(cbsacode year) cluster(cbsacode year)
	
	* IV Regressions
	ivreg2 axle_sr (dln_wap = d_sh_under5), cluster(year)
	ivreg2 bds_sr (dln_wap = d_sh_under5), cluster(year)
	ivreg2 axle_sr (dln_clf = d_sh_under5), cluster(year)
	ivreg2 bds_sr (dln_clf = d_sh_under5), cluster(year)
restore




* 3. Run regressions of change in ind share on LS growth -----------------------
bys cbsacode year: egen bds_all = total(bds_tot)
bys cbsacode year: egen axle_all = total(axle_tot)

gen ind_sh_bds = bds_tot/bds_all * 100
gen ind_sh_axle = axle_tot/axle_all * 100

gen d_ind_sh_bds = ind_sh_bds - L.ind_sh_bds
gen d_ind_sh_axle = ind_sh_axle - L.ind_sh_axle

foreach ind of local inds {
	* OLS FE Regressions
	*reghdfe d_ind_sh_axle dln_wap if naics2 != "`ind'", a(cbsacode year) cluster(cbsacode year)
	reghdfe d_ind_sh_bds dln_wap if naics2 != "`ind'", a(cbsacode year) cluster(cbsacode year)
	*reghdfe d_ind_sh_axle dln_clf if naics2 != "`ind'", a(cbsacode year) cluster(cbsacode year)
	*reghdfe d_ind_sh_bds dln_clf if naics2 != "`ind'", a(cbsacode year) cluster(cbsacode year)
	
	* IV Regressions
	*ivreg2 d_ind_sh_axle (dln_wap = d_sh_under5) if naics2 != "`ind'", cluster(year)
	ivreg2 d_ind_sh_bds (dln_wap = d_sh_under5) if naics2 != "`ind'", cluster(year)
	*ivreg2 d_ind_sh_axle (dln_clf = d_sh_under5) if naics2 != "`ind'", cluster(year)
	*ivreg2 d_ind_sh_bds (dln_clf = d_sh_under5) if naics2 != "`ind'", cluster(year)
}



