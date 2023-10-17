/*



*/


set scheme s1color


clear all
pause on

global proj_dir  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/"
cd "$proj_dir/raw-data/"


* Naics names
import delimited "../processed-data/naics2.csv", clear varn(1)
tempfile inds
save `inds', replace


* --- Startup Rate Data --- *

	local ii = 1
foreach n in "11" "21" "22" "23" "31-33" "42" "44-45" "48-49" "51" "52" ///
				"53" "54" "55" "56" "61" "62" "71" "72" "81" {
	
	* First read in BDS data by sector
	local filelist: dir "bds" files "bds_????_`n'.csv"
	cd "bds"
	foreach file of local filelist {
		import delimited "`file'", clear
		tostring v10, replace
		
		if `ii' == 1 {
			tempfile bds
			save `bds', replace
			local ++ii
		}
		else {
			append using `bds'
			save `bds', replace
		}
	}
	cd ../
}

rename (v1-v11) (rownum statename naics2desc year firmage firms estabs emp ///
		year2 naics2 statefips)

keep if inlist(firmage, 1, 10)

keep year statefips naics2 firmage firms estabs emp
reshape wide firms estabs emp, i(year statefips naics2) j(firmage)

merge m:1 naics2 using `inds', nogen

ren *1 *_tot
ren *10 *_age0

foreach var in "firms" "estabs" "emp" {
	gen `var'_inc = `var'_tot - `var'_age0
}

collapse (sum) *_tot *_age0 *_inc, by(naics2 naics2short year)

gen avg_wrks_perfirm_inc = emp_inc / firms_inc
gen avg_wrks_perfirm_age0 = emp_age0 / firms_age0

export delimited "$proj_dir/processed-data/workers_per_firm_bynaics2.csv", replace


* Industry distribution of workers
foreach grp in "age0" "inc" "tot" {
	if "`grp'" == "age0" {
		local subti "Entrants"
	}
	if "`grp'" == "inc" {
		local subti "Incumbents"
	}
	if "`grp'" == "tot" {
		local subti "All Firms"
	}
	
	
preserve
	gsort year -naics2
		
	gen inddist_y1 = 0 if naics2 == "81"
	gen inddist_y2 = emp_`grp' if naics2 == "81"
	foreach i in "72" "71" "62" "61" "56" "55" "54" "53" "52" "51" "48-49" ///
					"44-45" "42" "31-33" "23" "22" "21" "11" {
		replace inddist_y1 = inddist_y2[_n-1] if naics2 == "`i'"
		replace inddist_y2 = inddist_y1 + emp_`grp' if naics2 == "`i'"
	}
	
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
	  ti("Sector Distribution of Employment in `subti'") xti("Year") yti("Share of Workers (%)" " ")
	  xlab(1979(5)2019,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/figures/ts_emp_indfrac_`grp'.pdf", replace as(pdf);
	
	#delimit cr
restore
}
* ------------------------------------------------------------------------------

import delimited "$proj_dir/processed-data/workers_per_firm_bynaics2_hp.csv", clear

levelsof naics2, local(indlist)

foreach i of local indlist {
	
	if "`i'" == "11" {
		local subti "Agriculture"
	}
	if "`i'" == "21" {
		local subti "Mining"
	}
	if "`i'" == "22" {
		local subti "Utilities"
	}
	if "`i'" == "23" {
		local subti "Construction"
	}
	if "`i'" == "31-33" {
		local subti "Manufacturing"
	}
	if "`i'" == "42" {
		local subti "Wholesale Trade"
	}
	if "`i'" == "44-45" {
		local subti "Retail Trade"
	}
	if "`i'" == "48-49" {
		local subti "Transportation & Warehousing"
	}
	if "`i'" == "51" {
		local subti "Information"
	}
	if "`i'" == "52" {
		local subti "Finance & Insurance"
	}
	if "`i'" == "53" {
		local subti "Real Estate"
	}
	if "`i'" == "54" {
		local subti "Professional Services"
	}
	if "`i'" == "55" {
		local subti "Managment"
	}
	if "`i'" == "56" {
		local subti "Administrative, Support, and Waste Management"
	}
	if "`i'" == "61" {
		local subti "Educational Services"
	}
	if "`i'" == "62" {
		local subti "Health Care"
	}
	if "`i'" == "71" {
		local subti "Arts, Entertainment, and Recreation"
	}
	if "`i'" == "72" {
		local subti "Accommodation & Food"
	}
	if "`i'" == "81" {
		local subti "Other Services"
	}
	
	#delimit ;
	tw (line avg_wrks_perfirm_age0 year if naics2 == "`i'", lp(_) lc(lavender))
	   (line avg_wrks_perfirm_inc year if naics2 == "`i'", lp(_) lc(eltblue))
	   (line avg_wrks_perfirm_age0_hp year if naics2 == "`i'", lp(l) lc(purple))
	   (line avg_wrks_perfirm_inc_hp year if naics2 == "`i'", lp(l) lc(edkblue)),
	  legend(order(1 "Entrants (Raw)" 2 "Incumbents (Raw)"
					3 "Entrants (HP)" 4 "Incumbents (HP)") r(2))
	  yti("Avg. Workers per Firm") xti("Year") ti("Firm Size") subti("`subti'");
	#delimit cr
	
	graph export "$proj_dir/output/figures/ts_avg_wrks_perfirm-`i'.pdf", replace as(pdf)
}












