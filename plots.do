/*

plots.do

*/

set scheme s1color


clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

* State FIPS -> Abbreviation xwalk
import delimited "states.csv", clear varn(1)
tempfile st
save `st', replace

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
	
	collapse (mean) bds_sr_hp axle_sr_hp  wap_gr_hp, by(statefips)
	merge 1:1 statefips using `st', nogen keep(3)
	
	* DataAxle
	#delimit ;
	tw (lfit axle_sr_hp wap_gr_hp, lc(erose) lp(_))
	   (scatter axle_sr_hp wap_gr_hp, mc(cranberry) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(1979-2019)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(order(2 "DataAxle"));
	#delimit cr
	
	graph export "../output/figures/scatter_bds_sr_wapgr.png", replace as(png)

	* BDS
	#delimit ;
	tw (lfit bds_sr_hp wap_gr_hp, lc(eltblue) lp(_))
	   (scatter bds_sr_hp wap_gr_hp, mc(edkblue) msym("Oh")
						mlab(state) mlabsize(vsmall) mlabc(edkblue)),
	  ti("Startup Rate and Working-Age Population Growth by State")
	  subti("(1979-2019)") xti("Average WAP Growth Rate (%)")
	  yti("Average Startup Rate (%)") legend(order(2 "BDS"));
	#delimit cr
	
	graph export "../output/figures/scatter_bds_sr_wapgr.png", replace as(png)
	
restore

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
	

#delimit ;
tw (scatter dln_wap_hp l20_sh_under5_hp, mc(gs9) msym("O"))
   (lfit dln_wap_hp l20_sh_under5_hp, lc(black) lp(_)),
  ti("First Stage") xti("L20 Pop. Share Under Age 5 (%)")
  yti("WAP Growth (%)") legend(off);
#delimit cr

graph export "../output/figures/scatter_firststage.png", replace as(png)

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
