/*




*/




clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

* Aggregate
import delimited "aggregate_projections.csv", clear varn(1)
replace ols_pred = "" if ols_pred == "NA"
replace iv_pred = "" if iv_pred == "NA"
destring ols_pred iv_pred, replace


bys year: egen bds_sr_yrmean = mean(bds_sr_hp)
	gen sr_dem1 = bds_sr_hp - bds_sr_yrmean
bys statefips: egen bds_sr_stmean = mean(sr_dem1) if inrange(year,1980,2007)
	bys statefips: ereplace bds_sr_stmean = max(bds_sr_stmean)

gen r_base = ols_pred - (ols_coeff * dln_wap_hp)
bys statefips (year): replace r_base = r_base[_n-1] if r_base == .

gen ols = (ols_coeff * dln_wap_hp) + r_base
gen iv = (iv_coeff * iv_fs * l20_sh_under5_hp) + bds_sr_yrmean + bds_sr_stmean

replace ols = ols * 100
replace bds_sr_hp = bds_sr_hp * 100

sort statefips year 

#delimit ;
tw (line bds_sr_hp year if statefips == 17, lc(edkblue) lp(l))
   (scatter ols year if year <= 2007 & statefips == 17, msym(X) mc(eltblue))
   (scatter ols year if year >= 2008 & statefips == 17, msym(Oh) mc(ebblue)),
  ti("Observed and Predicted Startup Rate") subti("(Illinois)")
  legend(order(2 "In-Sample OLS" 3 "Out-of-Sample OLS"
				1 "Actual (HP Filtered) Startup Rate") r(3))
  xline(2007.5, lc(gs12) lp(-)) yti("Startup Rate (%)")
  note("In order to not incorporate future information into these projections, I apply the state and year"
		"fixed effect values from 2007 forward to 2008-2019.");
#delimit cr

gen age0_pred = ols_pred * tot_hp

gen age0_ols_pred = ols * tot_hp
gen age0_iv_pred = iv * tot_hp

collapse (sum) tot_hp age0_hp age0_pred age0_ols_pred age0_iv_pred, by(year) 
gen sr = age0_hp / tot_hp * 100
gen ols_pred = age0_ols_pred / tot_hp * 100
gen iv_pred = age0_iv_pred / tot_hp
gen r_pred = age0_pred / tot_hp * 100

#delimit ;
tw (line sr year, lc(edkblue) lp(l))
   (scatter r_pred year if year <= 2007, msym(X) mc(eltblue))
   (scatter ols_pred year if year >= 2008, msym(Oh) mc(ebblue)),
  ti("Observed and Predicted Startup Rate" "Aggregate")
  legend(order(2 "In-Sample OLS" 3 "Out-of-Sample OLS"
				1 "Actual (HP Filtered) Startup Rate") r(2))
  xline(2007.5, lc(gs12) lp(-))  yti("Startup Rate (%)")
  note("In order to not incorporate future information into these projections, I apply the state and year"
		"fixed effect values from 2007 forward to 2008-2019.");
#delimit cr

graph export "../output/figures/ts_predictions_agg.pdf", replace as(pdf)


* Construction
import delimited "construction_projections.csv", clear varn(1)
replace ols_pred = "" if ols_pred == "NA"
replace iv_pred = "" if iv_pred == "NA"
destring ols_pred iv_pred, replace


bys year: egen bds_sr_yrmean = mean(bds_sr_hp)
	gen sr_dem1 = bds_sr_hp - bds_sr_yrmean
bys statefips: egen bds_sr_stmean = mean(sr_dem1) if inrange(year,1980,2007)
	bys statefips: ereplace bds_sr_stmean = max(bds_sr_stmean)

gen r_base = ols_pred - (ols_coeff * dln_wap_hp)
bys statefips (year): replace r_base = r_base[_n-1] if r_base == .

gen ols = (ols_coeff * dln_wap_hp) + r_base
gen iv = (iv_coeff * iv_fs * l20_sh_under5_hp) + bds_sr_yrmean + bds_sr_stmean

sort statefips year 

#delimit ;
tw (line bds_sr_hp year if statefips == 17, lc(edkblue) lp(l))
   (scatter ols year if year <= 2007 & statefips == 17, msym(X) mc(eltblue))
   (scatter ols year if year >= 2008 & statefips == 17, msym(Oh) mc(ebblue)),
  ti("Observed and Predicted Startup Rate for Construction") subti("(Illinois)")
  legend(order(2 "In-Sample OLS" 3 "Out-of-Sample OLS"
				1 "Actual (HP Filtered) Startup Rate") r(3))
  xline(2007.5, lc(gs12) lp(-))
  note("In order to not incorporate future information into these projections, I apply the state and year"
		"fixed effect values from 2007 forward to 2008-2019.");
#delimit cr

gen age0_pred = ols_pred * bds_tot_hp

gen age0_ols_pred = ols * bds_tot_hp
gen age0_iv_pred = iv * bds_tot_hp

collapse (sum) bds_tot_hp bds_age0_hp age0_pred age0_ols_pred age0_iv_pred, by(year) 
gen sr = bds_age0_hp / bds_tot_hp * 100
gen ols_pred = age0_ols_pred / bds_tot_hp * 100
gen iv_pred = age0_iv_pred / bds_tot_hp
gen r_pred = age0_pred / bds_tot_hp * 100

#delimit ;
tw (line sr year, lc(edkblue) lp(l))
   (scatter r_pred year if year <= 2007, msym(X) mc(eltblue))
   (scatter ols_pred year if year >= 2008, msym(Oh) mc(ebblue)),
  ti("Observed and Predicted Startup Rate" "Construction")
  legend(order(2 "In-Sample OLS" 3 "Out-of-Sample OLS"
				1 "Actual (HP Filtered) Startup Rate") r(2))
  xline(2007.5, lc(gs12) lp(-)) yti("Startup Rate (%)")
  note("In order to not incorporate future information into these projections, I apply the state and year"
		"fixed effect values from 2007 forward to 2008-2019.");
#delimit cr


graph export "../output/figures/ts_predictions_construction.pdf", replace as(pdf)
