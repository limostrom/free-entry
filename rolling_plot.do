

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

import delimited "rolling_regs.csv", clear varn(1)

gen ols_lb = ols_coeff - (1.96 * ols_se)
gen ols_ub = ols_coeff + (1.96 * ols_se)

#delimit ;
tw (line ols_lb year, lp(_) lc(eltblue))
   (line ols_ub year, lp(_) lc(eltblue))
   (line ols_coeff year, lp(l) lc(edkblue)),
 legend(order(3 "Point Estimate" 1 "95% Confidence Interval") r(1))
 yti("OLS Coefficient") xti("Year" "(Window End)") xlab(1989(5)2019)
 ti("Change in Elasticity Over Time") subti("10-Year Rolling Windows")
 yline(0,lc(gs12) lp(-));
#delimit cr

graph export "../output/figures/rolling_10yr_ols_coeffs.pdf", replace as(pdf)

import delimited "rolling_regs_fd.csv", clear varn(1)

gen ols_lb = ols_coeff - (1.96 * ols_se)
gen ols_ub = ols_coeff + (1.96 * ols_se)

#delimit ;
tw (line ols_lb year, lp(_) lc(eltblue))
   (line ols_ub year, lp(_) lc(eltblue))
   (line ols_coeff year, lp(l) lc(edkblue)),
 legend(order(3 "Point Estimate" 1 "95% Confidence Interval") r(1))
 yti("First-Differences Coefficient") xti("Year" "(Window End)") xlab(1989(5)2019)
 ti("Change in Elasticity Over Time") subti("10-Year Rolling Windows")
 yline(0,lc(gs12) lp(-));
#delimit cr

graph export "../output/figures/rolling_10yr_fd_coeffs.pdf", replace as(pdf)



* Naics names
import delimited "naics2.csv", clear varn(1)
tempfile inds
save `inds', replace



cd ../
local filelist: dir "processed-data" files "rolling_regs_fd_*.csv"
cd "processed-data"
foreach f of local filelist {
	import delimited "`f'", clear varn(1)
	gen naics2 = substr("`f'", 17, 2)
		replace naics2 = "31-33" if naics2 == "31"
		replace naics2 = "44-45" if naics2 == "44"
		replace naics2 = "48-49" if naics2 == "48"
		local indcode = naics2
		dis "`indcode'"
	
	gen ols_lb = ols_coeff - (1.96 * ols_se)
	gen ols_ub = ols_coeff + (1.96 * ols_se)
	
	merge m:1 naics2 using `inds', nogen keep(3)
	local indname = naics2short
	dis "`indname'"
	
	#delimit ;
	tw (line ols_lb year, lp(_) lc(eltblue))
	   (line ols_ub year, lp(_) lc(eltblue))
	   (line ols_coeff year, lp(l) lc(edkblue)),
	 legend(order(3 "Point Estimate" 1 "95% Confidence Interval") r(1))
	 yti("First Differences Coefficient") xti("Year" "(Window End)") xlab(1989(5)2019)
	 ti("Elasticity for `indname'") subti("10-Year Rolling Windows")
	 yline(0,lc(gs12) lp(-));
	#delimit cr

	graph export "../output/figures/rolling_10yr_ols_coeffs_`indcode'.pdf", replace as(pdf)


}
