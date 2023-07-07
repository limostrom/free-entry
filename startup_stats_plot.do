
/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

startup_stats_plot.do

*/

pause on

global data_dir "/Volumes/Seagate Por/infogroup in Dropbox DevBanks/_original_data/"
global proj_dir "/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism"

cap mkdir "$proj_dir/processed-data/"
cap mkdir "$proj_dir/processed-data/startup_rates/"


#delimit ;
local varlist "company employeesize5location employeesize6corporate modeledemployeesize
				parentnumber callstatuscode teleresearchupdatedate year1stappeared
				 yearestablished cbsacode fipscode censustract zipcode
				primarynaicscode primarysiccode";
#delimit cr




*-------------------------------------------------------------------------------
* Aggregate Appending
use "$proj_dir/processed-data/startup_rates/agg1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/agg`y'.dta"
}

tempfile aggregate
save `aggregate', replace


use "$proj_dir/processed-data/startup_rates/agg1997_sr.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/agg`y'_sr.dta"
}

merge 1:1 year using `aggregate', assert(3)

#delimit ;

tw (line n_firms year, lc(edkblue))
   (line new_firm year, lc(eltblue)),
  legend(order(2 "# New Firms" 1 "Total Firms") r(1))
  ti("All Firms") xti("Year") yti("")
  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
graph export "$proj_dir/output/firms_ts_agg.png", replace as(png);

#delimit cr

* Note: data quality much worse 1999-2002 (UPDATE: Fixed now, hopefully)
*drop if year < 2003 

#delimit ;

tw (rcap sr_p25 sr_p75 year, lc(edkblue))
   (scatter sr year, msym(O) mc(eltblue))
   (scatter sr_mean year, msym(X) mc(edkblue)),
  legend(order(2 "Startup Rate" 3 "Mean SR Across States" 1 "IQR Across States") r(1))
  ti("Aggregate Startup Rate") xti("Year") yti("")
  xlab(1997(3)2021,labsize(small)) ylab(0(0.02)0.08,labsize(small));
graph export "$proj_dir/output/startup_ts_agg.png", replace as(png);

#delimit cr

* By Industry // ---------------------------------------------------------------

use "$proj_dir/processed-data/startup_rates/ind1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/ind`y'.dta"
}

tempfile industry
save `industry', replace


use "$proj_dir/processed-data/startup_rates/ind1997_sr.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/ind`y'_sr.dta"
}

merge 1:1 year naics2 naics2desc using `industry', assert(3)


foreach ind of global industries {
	#delimit ;
	
	tw (line n_firms year if strpos(naics2desc,"`ind'") > 0, lc(edkblue))
	   (line new_firm year if strpos(naics2desc,"`ind'") > 0, lc(eltblue)),
	  legend(order(2 "# New Firms" 1 "Total Firms") r(1))
	  ti("`ind' Firms") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firms_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr
}


* Note: data quality much worse 1999-2002 (UPDATE: Fixed now, hopefully)
*drop if year < 2003 

foreach ind of global industries {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(naics2desc,"`ind'") > 0, lc(edkblue))
	   (scatter sr year if strpos(naics2desc,"`ind'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(naics2desc,"`ind'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across CBSAs" 1 "IQR Across CBSAs") r(1))
	  ti("`ind' Startup Rate") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr

}

* By CBSA (tracts)

use "$proj_dir/processed-data/startup_rates/cbsa1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'.dta"
}

tempfile metros
save `metros', replace


use "$proj_dir/processed-data/startup_rates/cbsa1997_sr.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'_sr.dta"
}

merge 1:1 year cbsaname using `metros', assert(3)


foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (line n_firms year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (line new_firm year if strpos(cbsaname,"`city'") > 0, lc(eltblue)),
	  legend(order(2 "# New Firms" 1 "Total Firms") r(1))
	  ti("`city' Firms") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firms_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr
}


* Note: data quality much worse 1999-2002 (UPDATE: Fixed now, hopefully)
*drop if year < 2003 


foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (scatter sr year if strpos(cbsaname,"`city'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(cbsaname,"`city'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across Tracts" 1 "IQR Across Tracts") r(1))
	  ti("`city' Startup Rate") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr

}

* By CBSA (zipcodes)

use "$proj_dir/processed-data/startup_rates/cbsa1997_zip.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'_zip.dta"
}

tempfile metros
save `metros', replace


use "$proj_dir/processed-data/startup_rates/cbsa1997_sr.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'_sr.dta"
}

merge 1:1 year cbsaname using `metros', assert(3)


foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (line n_firms year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (line new_firm year if strpos(cbsaname,"`city'") > 0, lc(eltblue)),
	  legend(order(2 "# New Firms" 1 "Total Firms") r(1))
	  ti("`city' Firms") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firms_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr
}

* Note: data quality much worse 1999-2002 (UPDATE: Fixed now, hopefully)
*drop if year < 2003 




foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (scatter sr year if strpos(cbsaname,"`city'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(cbsaname,"`city'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across Zipcodes" 1 "IQR Across Zipcodes") r(1))
	  ti("`city' Startup Rate") xti("Year") yti("")
	  xlab(1997(3)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr

}




