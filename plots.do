/*

plots.do

*/

set scheme s1color


clear all
pause on

global proj_dir  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/"
cd "$proj_dir/processed-data/"

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
gen l20_birthrate = l20_births/l20_pop * 1000
gen l20_sh_under5 = l20_pop_under5 / l20_pop
gen l20_sh_under5_hp = l20_pop_under5_hp / l20_pop_hp
gen l20_d_sh_under5 = l20_sh_under5 - l.l20_sh_under5
gen l20_d_sh_under5_hp = l20_sh_under5_hp - l.l20_sh_under5_hp

tempfile rhs
save `rhs', replace


* Now load in LHS: BDS and DataAxle Startup Rates
import delimited "lhs_bystate.csv", clear varn(1)
local varlist bds_sr axle_age0 axle_tot axle_tot_hp axle_age0_hp axle_sr axle_sr_hp

foreach var of local varlist {
	replace `var' = "" if `var' == "NA"
}
destring `varlist', replace

merge m:1 statefips year using `rhs', keep(1 3)

*%%%%%%%%%%%%%%%%%%%% FIGURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


* Bar chart of drop in startup rate by sector
preserve
	collapse (sum) bds_age0_hp bds_tot_hp, by(naics2 year)
	drop if naics2 == "92"
	
	keep if inlist(year, 1979, 2007)
	gen sr = bds_age0_hp / bds_tot_hp * 100
		drop bds_age0_hp bds_tot_hp
	reshape wide sr, i(naics2) j(year)
	
	gen d_sr = sr2007 - sr1979
	merge 1:1 naics2 using `inds', nogen keep(3)
	
	sort d_sr
	#delimit ;
	graph hbar d_sr, over(naics2short, label(labsize(small)) sort(d_sr))
					xalt yti("Change in Startup Rate (%pts)" "1979-2007")
					bar(1, color(edkblue));
	#delimit cr
	graph export "../output/figures/bars_dSR.pdf", replace as(pdf)
	
	#delimit ;
	tw (scatter sr1979 d_sr, msym(Oh) mc(eltblue) mlab(naics2short) mlabc(edkblue)),
	  legend(off) yti("Startup Rate in 1979") xti("Change in Startup Rate (1979-2007)");
	#delimit cr
	graph export "../output/figures/scatter_SR1979_dSR.pdf", replace as(pdf)
	
	#delimit ;
	tw (scatter sr1979 d_sr, msym(Oh) mc(eltblue) mlab(naics2short) mlabc(edkblue)),
	  legend(off) yti("Startup Rate in 1979") xti("Startup Rate in 2007");
	#delimit cr
	graph export "../output/figures/scatter_SR1979_SR2007.pdf", replace as(pdf)
	
restore



* Long time series of startup and exit rates in BDS

preserve
	collapse (sum) bds_age0 bds_tot bds_age0_hp bds_tot_hp, by(year)
	tsset year
	
	gen bds_exits = bds_tot - f.bds_tot + f.bds_age0
	gen bds_exits_hp = bds_tot_hp - f.bds_tot_hp + f.bds_age0_hp
	
	foreach var of varlist bds_age0 bds_age0_hp bds_exits bds_exits_hp {
		replace `var' = `var' / 1000
	}

	#delimit ;
	tw (line bds_exits year, lc(erose) lp(_))
	   (line bds_age0 year, lc(eltblue) lp(_))
	   (line bds_exits_hp year, lc(cranberry) lp(l))
	   (line bds_age0_hp year , lc(edkblue) lp(l)),
	  legend(order(2 "Startups (Raw)" 1 "Exits (Raw)"
					4 "Startups (HP)" 3 "Exits (HP)") r(2))
	  ti("Entering and Exiting Firms") xti("") yti("Number of Firms (Thousands)")
	  name(fig1a, replace)
	  note("Source: U.S. Census Bureau Business Dynamics Statistics."
			"Time series are HP filtered using a smoothing parameter of 6.25");
	
	graph export "../output/figures/ts_startups_exits.pdf", replace as(pdf);
	
	#delimit cr
	
	foreach var of varlist bds_age0 bds_age0_hp bds_exits bds_exits_hp {
		replace `var' = `var' * 1000
	}
	
	gen er = bds_exits / bds_tot * 100
	gen er_hp = bds_exits_hp / bds_tot_hp * 100
	gen sr = bds_age0 / bds_tot * 100
	gen sr_hp = bds_age0_hp / bds_tot_hp * 100
	
	

	#delimit ;
	tw (line er year, lc(erose) lp(_))
	   (line sr year, lc(eltblue) lp(_))
	   (line er_hp year, lc(cranberry) lp(l))
	   (line sr_hp year , lc(edkblue) lp(l)),
	  legend(order(2 "Startup Rate (Raw)" 1 "Exit Rate (Raw)"
					4 "Startup Rate (HP)" 3 "Exit Rate (HP)") r(2))
	  ti("Startup and Exit Rates") xti("") yti("% of Firms")
	  name(fig1b, replace)
	  note("Source: U.S. Census Bureau Business Dynamics Statistics."
			"Time series are HP filtered using a smoothing parameter of 6.25");
	#delimit cr
	
	graph export "../output/figures/ts_sr_er.pdf", replace as(pdf)
	
	
	graph combine fig1a fig1b, r(1)
	graph export "../output/figures/figure1.pdf", replace as(pdf)
	

restore

* Heterogeneity Across States and Industries
preserve // by states
	collapse (sum) bds_age0_hp bds_tot_hp, by(statefips year)
	xtset statefips year
	
	gen bds_exits_hp = bds_tot_hp - f.bds_tot_hp + f.bds_age0_hp
	
	gen er_hp = bds_exits_hp / bds_tot_hp * 100
	gen sr_hp = bds_age0_hp / bds_tot_hp * 100
	
	collapse (sum) bds_age0_hp bds_exits_hp bds_tot_hp ///
			 (p25) sr_p25 = sr_hp er_p25 = er_hp ///
			 (p75) sr_p75 = sr_hp er_p75 = er_hp, by(year)
	gen sr = bds_age0_hp / bds_tot_hp * 100
	gen er = bds_exits_hp / bds_tot_hp * 100
	
	#delimit ;
	tw (line sr_p25 year, lc(eltblue) lp(_))
	   (line sr_p75 year, lc(eltblue) lp(_))
	   (line sr year, lc(edkblue) lp(l)),
	legend(order(3 "Aggregate Startup Rate" 1 "IQR Across States") r(1))
	ti("Startup Rate Heterogeneity Across States")
	xti("") yti("% of Firms")
	note("Source: U.S. Census Bureau Business Dynamics Statistics."
		"Time series are HP filtered using a smoothing parameter of 6.25");
	
	graph export "../output/figures/ts_sr_het_bystate.pdf", replace as(pdf);
	
	#delimit cr
restore

preserve // by sectors
	collapse (sum) bds_age0_hp bds_tot_hp, by(naics2 year)
	egen naics2id = group(naics2)
	xtset naics2id year
	
	gen bds_exits_hp = bds_tot_hp - f.bds_tot_hp + f.bds_age0_hp
	
	gen er_hp = bds_exits_hp / bds_tot_hp * 100
	gen sr_hp = bds_age0_hp / bds_tot_hp * 100
	
	collapse (sum) bds_age0_hp bds_exits_hp bds_tot_hp ///
			 (p25) sr_p25 = sr_hp er_p25 = er_hp ///
			 (p75) sr_p75 = sr_hp er_p75 = er_hp, by(year)
	gen sr = bds_age0_hp / bds_tot_hp * 100
	gen er = bds_exits_hp / bds_tot_hp * 100
	
	#delimit ;
	tw (line sr_p25 year, lc(eltblue) lp(_))
	   (line sr_p75 year, lc(eltblue) lp(_))
	   (line sr year, lc(edkblue) lp(l)),
	legend(order(3 "Aggregate Startup Rate" 1 "IQR Across Sectors") r(1))
	ti("Startup Rate Heterogeneity Across Sectors")
	xti("") yti("% of Firms")
	note("Source: U.S. Census Bureau Business Dynamics Statistics. Sectors are defined as 2-digit NAICS."
		"Time series are HP filtered using a smoothing parameter of 6.25");
	
	graph export "../output/figures/ts_sr_het_bysector.pdf", replace as(pdf);
	
	#delimit cr
restore


* Labor Supply Growth & Startup Rate Over Time
preserve
	collapse (sum) bds_age0 bds_age0_hp bds_tot bds_tot_hp wap wap_hp, by(year)
	tsset year
	gen sr_hp = bds_age0_hp / bds_tot_hp * 100
	gen sr = bds_age0 / bds_tot * 100
	gen wap_gr_hp = (ln(wap_hp) - ln(l.wap_hp)) * 100
	gen wap_gr = (ln(wap) - ln(l.wap)) * 100
	#delimit ;
	tw (line wap_gr year, lc(eltgreen) lp(l))
	   (line sr year, lc(eltblue) lp(l))
	   (line wap_gr_hp year, lc(forest_green) lp(l))
	   (line sr_hp year, lc(edkblue) lp(l)),
	ti("Startup Rate and Labor Supply Growth") yti("%") xti("Year")
	legend(order(2 "Startup Rate (Raw)" 1 "WAP Growth (Raw)"
				 4 "Startup Rate (HP)" 3 "WAP Growth (HP)"))
	note("Sources: U.S. Census Bureau Business Dynamics Statistics, Intercensal Tables (1979-2004),"
		"and ACS (2005-2019). Time series are HP filtered using a smoothing parameter of 6.25");
	#delimit cr
	graph export "../output/figures/ts_sr_wapgr.pdf", replace as(png)
	
	
	gen d_sr = sr - l.sr
	gen d_sr_hp = sr_hp - l.sr_hp
	
	
	#delimit ;
	tw (line d_sr year, lc(eltblue) lp(_))
	   (line d_sr_hp year , lc(edkblue) lp(l)),
	  legend(order(1 "Raw" 2 "HP Filtered") r(1))
	  yline(0,lc(gs12) lp(-))
	  ti("Change in Startup Rate From Previous Year") xti("") yti("Change in Startup Rate (%pts)")
	  note("Source: U.S. Census Bureau Business Dynamics Statistics."
			"Time series are HP filtered using a smoothing parameter of 6.25");
	#delimit cr
	
	graph export "../output/figures/ts_d_sr.pdf", replace as(pdf)
	
restore
*/
* Industry distribution of age 0 firms
preserve
	collapse (sum) bds_age0, by(naics2 year)
	merge m:1 naics2 using `inds', nogen
	gsort year -naics2
		
	gen inddist_y1 = 0 if naics2 == "81"
	gen inddist_y2 = bds_age0 if naics2 == "81"
	foreach i in "72" "71" "62" "61" "56" "55" "54" "53" "52" "51" "48-49" ///
					"44-45" "42" "31-33" "23" "22" "21" "11" {
		replace inddist_y1 = inddist_y2[_n-1] if naics2 == "`i'"
		replace inddist_y2 = inddist_y1 + bds_age0 if naics2 == "`i'"
	}


	replace inddist_y1 = inddist_y1/1000
	replace inddist_y2 = inddist_y2/1000

	#delimit ;
	
	tw (rarea inddist_y1 inddist_y2 year if naics2=="11", col(sandb))
	   (rarea inddist_y1 inddist_y2 year if naics2=="21", col(sand))
	   (rarea inddist_y1 inddist_y2 year if naics2=="22", col(erose))
	   (rarea inddist_y1 inddist_y2 year if naics2=="23", col(brown))
	   (rarea inddist_y1 inddist_y2 year if naics2=="31-33", col(sienna))
	   (rarea inddist_y1 inddist_y2 year if naics2=="42", col(olive_teal))
	   (rarea inddist_y1 inddist_y2 year if naics2=="44-45", col(eltgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="48-49", col(forest_green))
	   (rarea inddist_y1 inddist_y2 year if naics2=="51", col(dkgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="52", col(eltblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="53", col(ebblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="54", col(emidblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="55", col(edkblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="56", col(dknavy))
	   (rarea inddist_y1 inddist_y2 year if naics2=="61", col(bluishgray))
	   (rarea inddist_y1 inddist_y2 year if naics2=="62", col(gs12))
	   (rarea inddist_y1 inddist_y2 year if naics2=="71", col(gs10))
	   (rarea inddist_y1 inddist_y2 year if naics2=="72", col(gs8))
	   (rarea inddist_y1 inddist_y2 year if naics2=="81", col(gs6)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs") r(5) symx(small) symy(small))
	  ti("Sector Distribution of New Firms") xti("Year") yti("# of Firms (thousands)" " ")
	  xlab(1979(5)2019,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/figures/ts_bds_inddist_age0.pdf", replace as(pdf);
	
	#delimit cr
	
	replace inddist_y1 = inddist_y1 * 1000
	replace inddist_y2 = inddist_y2 * 1000
	
	bys year: egen yr_total = max(inddist_y2)
	gen indfrac_y1 = inddist_y1 / yr_total * 100
	gen indfrac_y2 = inddist_y2 / yr_total * 100
	
	
	#delimit ;
	
	tw (rarea indfrac_y1 indfrac_y2 year if naics2=="11", col(sandb))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="21", col(sand))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="22", col(erose))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="23", col(brown))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="31-33", col(sienna))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="42", col(olive_teal))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="44-45", col(eltgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="48-49", col(forest_green))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="51", col(dkgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="52", col(eltblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="53", col(ebblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="54", col(emidblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="55", col(edkblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="56", col(dknavy))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="61", col(bluishgray))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="62", col(gs12))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="71", col(gs10))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="72", col(gs8))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="81", col(gs6)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs") r(5)  symx(small) symy(small))
	  ti("Sector Distribution of New Firms") xti("Year") yti("Share of Firms (%)" " ")
	  xlab(1979(5)2019,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/figures/ts_bds_indfrac_age0.pdf", replace as(pdf);
	
	#delimit cr
restore

* Industry distribution of all firms
preserve
	collapse (sum) bds_tot, by(naics2 year)
	merge m:1 naics2 using `inds', nogen
	gsort year -naics2
		
	gen inddist_y1 = 0 if naics2 == "81"
	gen inddist_y2 = bds_tot if naics2 == "81"
	foreach i in "72" "71" "62" "61" "56" "55" "54" "53" "52" "51" "48-49" ///
					"44-45" "42" "31-33" "23" "22" "21" "11" {
		replace inddist_y1 = inddist_y2[_n-1] if naics2 == "`i'"
		replace inddist_y2 = inddist_y1 + bds_tot if naics2 == "`i'"
	}


	replace inddist_y1 = inddist_y1/1000
	replace inddist_y2 = inddist_y2/1000

	#delimit ;
	
	tw (rarea inddist_y1 inddist_y2 year if naics2=="11", col(sandb))
	   (rarea inddist_y1 inddist_y2 year if naics2=="21", col(sand))
	   (rarea inddist_y1 inddist_y2 year if naics2=="22", col(erose))
	   (rarea inddist_y1 inddist_y2 year if naics2=="23", col(brown))
	   (rarea inddist_y1 inddist_y2 year if naics2=="31-33", col(sienna))
	   (rarea inddist_y1 inddist_y2 year if naics2=="42", col(olive_teal))
	   (rarea inddist_y1 inddist_y2 year if naics2=="44-45", col(eltgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="48-49", col(forest_green))
	   (rarea inddist_y1 inddist_y2 year if naics2=="51", col(dkgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="52", col(eltblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="53", col(ebblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="54", col(emidblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="55", col(edkblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="56", col(dknavy))
	   (rarea inddist_y1 inddist_y2 year if naics2=="61", col(bluishgray))
	   (rarea inddist_y1 inddist_y2 year if naics2=="62", col(gs12))
	   (rarea inddist_y1 inddist_y2 year if naics2=="71", col(gs10))
	   (rarea inddist_y1 inddist_y2 year if naics2=="72", col(gs8))
	   (rarea inddist_y1 inddist_y2 year if naics2=="81", col(gs6)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs") r(5)  symx(small) symy(small))
	  ti("Sector Distribution of All Firms") xti("Year") yti("# of Firms (thousands)" " ")
	  xlab(1979(5)2019,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/figures/ts_bds_inddist.pdf", replace as(pdf);
	
	#delimit cr
	
	replace inddist_y1 = inddist_y1 * 1000
	replace inddist_y2 = inddist_y2 * 1000
	
	bys year: egen yr_total = max(inddist_y2)
	gen indfrac_y1 = inddist_y1 / yr_total * 100
	gen indfrac_y2 = inddist_y2 / yr_total * 100
	
	
	#delimit ;
	
	tw (rarea indfrac_y1 indfrac_y2 year if naics2=="11", col(sandb))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="21", col(sand))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="22", col(erose))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="23", col(brown))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="31-33", col(sienna))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="42", col(olive_teal))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="44-45", col(eltgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="48-49", col(forest_green))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="51", col(dkgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="52", col(eltblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="53", col(ebblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="54", col(emidblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="55", col(edkblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="56", col(dknavy))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="61", col(bluishgray))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="62", col(gs12))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="71", col(gs10))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="72", col(gs8))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="81", col(gs6)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs") r(5)  symx(small) symy(small))
	  ti("Sector Distribution of All Firms") xti("Year") yti("Share of Firms (%)" " ")
	  xlab(1979(5)2019,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/figures/ts_bds_indfrac.pdf", replace as(pdf);
	
	#delimit cr
restore

/*
* New firms in DataAxle and BDS over time (national, across industries)
preserve
	collapse (sum) bds_age0 axle_age0 bds_age0_hp axle_age0_hp, by(year)
	local varlist bds_age0 axle_age0 bds_age0_hp axle_age0_hp
	foreach var of local varlist {
		replace `var' = `var'/1000
	}
	
	#delimit ;
	tw (line bds_age0 year, lc(eltblue) lp(_))
	   (line axle_age0 year if year >= 1997, lc(erose) lp(_))
	   (line bds_age0_hp year, lc(edkblue) lp(l))
	   (line axle_age0_hp year if year >= 1997, lc(cranberry) lp(l)),
	  legend(order(1 "BDS (Raw)" 2 "DataAxle (Raw)"
					3 "BDS (HP Filtered)" 4 "DataAxle (HP Filtered)") r(2))
	  ti("BDS & DataAxle Comparison") subti("New Business Formation")
	  xti("") yti("Number of New Firms (Thousands)");
	#delimit cr
	
	graph export "../output/figures/newfirms_ts_comparison.png", replace as(png)
restore

* Total firms in DataAxle and BDS over time (national, across industries)
preserve
	collapse (sum) bds_tot axle_tot bds_tot_hp axle_tot_hp, by(year)
	local varlist bds_tot axle_tot bds_tot_hp axle_tot_hp
	foreach var of local varlist {
		replace `var' = `var'/1000000
	}
	#delimit ;
	tw (line bds_tot year, lc(eltblue) lp(_))
	   (line axle_tot year if year >= 1997, lc(erose) lp(_))
	   (line bds_tot_hp year, lc(edkblue) lp(l))
	   (line axle_tot_hp year if year >= 1997, lc(cranberry) lp(l)),
	  legend(order(1 "BDS (Raw)" 2 "DataAxle (Raw)"
					3 "BDS (HP Filtered)" 4 "DataAxle (HP Filtered)") r(2))
	  ti("BDS & DataAxle Comparison") subti("All Firms")
	  xti("") yti("Total Number of Firms (Millions)");
	#delimit cr
	
	graph export "../output/figures/totfirms_ts_comparison.png", replace as(png)
restore

* Scatter of mean startup rate and WAP growth rate by statefips (across industries)
preserve
	collapse (sum) axle_tot_hp bds_tot_hp axle_age0_hp bds_age0_hp ///
			 (first) dln_wap_hp wap_hp, by(statefips year)
	xtset statefips year
	gen wap_gr_hp = (wap_hp - l.wap_hp) / l.wap_hp * 100
	replace dln_wap_hp = dln_wap_hp * 100
	gen axle_sr_hp = axle_age0_hp / axle_tot_hp * 100 if year >= 1997
	gen bds_sr_hp = bds_age0_hp / bds_tot_hp * 100
	
	gen repgrp = inrange(year,1979,2007)
	assert inrange(year,2008,2019) if repgrp == 0
	
	collapse (mean) bds_sr_hp axle_sr_hp wap_gr_hp, by(statefips repgrp)
	merge m:1 statefips using `st', nogen keep(3)
	
	* DataAxle
	#delimit ;
	tw (lfit axle_sr_hp wap_gr_hp if repgrp == 1, lc(erose) lp(_))
	   (scatter axle_sr_hp wap_gr_hp if repgrp == 1, mc(cranberry) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(1979-2007)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(order(2 "DataAxle"));
	#delimit cr
	
	graph export "../output/figures/scatter_da_sr_wapgr_80-07.pdf", replace as(pdf)
	
	#delimit ;
	tw (lfit axle_sr_hp wap_gr_hp if repgrp == 0, lc(erose) lp(_))
	   (scatter axle_sr_hp wap_gr_hp if repgrp == 0, mc(cranberry) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(2008-2019)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(order(2 "DataAxle"));
	#delimit cr
	
	graph export "../output/figures/scatter_da_sr_wapgr_08-19.pdf", replace as(pdf)

	* BDS
	#delimit ;
	tw (lfit bds_sr_hp wap_gr_hp if repgrp == 1, lc(eltblue) lp(_))
	   (scatter bds_sr_hp wap_gr_hp if repgrp == 1, mc(edkblue) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(1979-2007)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(off)
	  note("Source: U.S. Census Bureau Business Dynamics Statistics."
			"Time series are HP filtered using a smoothing parameter of 6.25");
	#delimit cr
	
	graph export "../output/figures/scatter_bds_sr_wapgr_80-07.pdf", replace as(pdf)
	
	#delimit ;
	tw (lfit bds_sr_hp wap_gr_hp if repgrp == 0, lc(eltblue) lp(_))
	   (scatter bds_sr_hp wap_gr_hp if repgrp == 0, mc(edkblue) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(2008-2019)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(off)
	  note("Source: U.S. Census Bureau Business Dynamics Statistics."
			"Time series are HP filtered using a smoothing parameter of 6.25");
	#delimit cr
	
	graph export "../output/figures/scatter_bds_sr_wapgr_08-19.pdf", replace as(pdf)
	
restore*/
* Scatter of relationship between WAP Growth and Instrument
use `rhs', clear
xtset statefips year
drop if statefips == 72
merge m:1 statefips using `st', nogen assert(3)
replace dln_wap_hp = dln_wap_hp*100
replace l20_sh_under5_hp = l20_sh_under5_hp * 100

bys statefips: egen dln_wap_hp_stmean = mean(dln_wap_hp)
	gen dln_wap_hp_demeaned = dln_wap_hp - dln_wap_hp_stmean
	bys year: egen dln_wap_hp_demeaned_yrmean = mean(dln_wap_hp_demeaned)
	gen dln_wap_hp_demeaned2 = dln_wap_hp_demeaned - dln_wap_hp_demeaned_yrmean
	
bys statefips: egen l20_sh_under5_hp_stmean = mean(l20_sh_under5_hp)
	gen l20_sh_under5_hp_demeaned = l20_sh_under5_hp - l20_sh_under5_hp_stmean
	bys year: egen l20_sh_under5_hp_demeaned_yrmean = mean(l20_sh_under5_hp_demeaned)
	gen l20_sh_under5_hp_demeaned2 = l20_sh_under5_hp_demeaned - l20_sh_under5_hp_demeaned_yrmean
	
bys statefips: egen l20_birthrate_stmean = mean(l20_birthrate)
	gen l20_birthrate_demeaned = l20_birthrate - l20_birthrate_stmean
	bys year: egen l20_birthrate_demeaned_yrmean = mean(l20_birthrate_demeaned)
	gen l20_birthrate_demeaned2 = l20_birthrate_demeaned - l20_birthrate_demeaned_yrmean
	
reg dln_wap_hp l20_sh_under5_hp
local slope = round(e(b)[1,1], 0.001)

#delimit ;
tw (scatter dln_wap_hp l20_sh_under5_hp, mc(gs9) msym("O"))
   (lfit dln_wap_hp l20_sh_under5_hp, lc(black) lp(_)),
  ti("First Stage") xti("L20 Pop. Share Under Age 5 (%)")
  yti("WAP Growth (%)") legend(off) text(-2 14 "Slope = `slope'");
#delimit cr

graph export "../output/figures/scatter_firststage.pdf", replace as(pdf)

sdf

#delimit ;
tw (scatter dln_wap_hp_demeaned2 l20_sh_under5_hp_demeaned2, mc(gs9) msym("O"))
   (lfit dln_wap_hp_demeaned2 l20_sh_under5_hp_demeaned2, lc(black) lp(_)),
	  ti("First Stage: `s'") subti("After Demeaning by State & Year")
	  xti("L20 Pop. Share Under Age 5 (%)") yti("WAP Growth (%)") legend(off);
#delimit cr

graph export "../output/figures/scatter_firststage_demeaned.png", replace as(png)

levelsof state, local(statelist)
foreach s of local statelist {
		
	#delimit ;
	tw (scatter dln_wap_hp l20_sh_under5_hp if state == "`s'", mc(gs9) msym("O"))
	   (lfit dln_wap_hp l20_sh_under5_hp if state == "`s'", lc(black) lp(_)),
	  ti("First Stage: `s'") xti("L20 Pop. Share Under Age 5 (%)")
	  yti("WAP Growth (%)") legend(off);
	#delimit cr

	graph export "../output/figures/scatter_firststage-`s'.png", replace as(png)
	
	#delimit ;
	tw (scatter dln_wap_hp_demeaned2 l20_sh_under5_hp_demeaned2 if state == "`s'", mc(gs9) msym("O"))
	   (lfit dln_wap_hp_demeaned2 l20_sh_under5_hp_demeaned2 if state == "`s'", lc(black) lp(_)),
	  ti("First Stage: `s'") subti("After Demeaning by State & Year")
	  xti("L20 Pop. Share Under Age 5 (%)") yti("WAP Growth (%)") legend(off);
	#delimit cr

	graph export "../output/figures/scatter_firststage_demeaned-`s'.png", replace as(png)
}
* Using birthrate instead

#delimit ;
tw (scatter dln_wap_hp l20_birthrate, mc(gs9) msym("O"))
   (lfit dln_wap_hp l20_birthrate, lc(black) lp(_)),
  ti("First Stage") xti("L20 Birthrate")
  yti("WAP Growth (%)") legend(off);
#delimit cr

graph export "../output/figures/scatter_birth1stStage.png", replace as(png)

#delimit ;
tw (scatter dln_wap_hp_demeaned2 l20_birthrate_demeaned2, mc(gs9) msym("O"))
   (lfit dln_wap_hp_demeaned2 l20_birthrate_demeaned2, lc(black) lp(_)),
	  ti("First Stage: `s'") subti("After Demeaning by State & Year")
	  xti("L20 Birthrate)") yti("WAP Growth (%)") legend(off);
#delimit cr

graph export "../output/figures/scatter_birth1stStage_demeaned.png", replace as(png)

levelsof state, local(statelist)
foreach s of local statelist {
		
	#delimit ;
	tw (scatter dln_wap_hp l20_birthrate if state == "`s'", mc(gs9) msym("O"))
	   (lfit dln_wap_hp l20_birthrate if state == "`s'", lc(black) lp(_)),
	  ti("First Stage: `s'") xti("L20 Birthrate")
	  yti("WAP Growth (%)") legend(off);
	#delimit cr

	graph export "../output/figures/scatter_birth1stStage-`s'.png", replace as(png)
	
	#delimit ;
	tw (scatter dln_wap_hp_demeaned2 l20_birthrate_demeaned2 if state == "`s'", mc(gs9) msym("O"))
	   (lfit dln_wap_hp_demeaned2 l20_birthrate_demeaned2 if state == "`s'", lc(black) lp(_)),
	  ti("First Stage: `s'") subti("After Demeaning by State & Year")
	  xti("L20 Birthrate") yti("WAP Growth (%)") legend(off);
	#delimit cr

	graph export "../output/figures/scatter_birth1stStage_demeaned-`s'.png", replace as(png)
}
