/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

startup_stats.do

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

forval y = 1997/2021 {

if `y' <= 2021 {
	use abi `varlist' using "$data_dir/`y'.dta", clear
}
if `y' == 2022 {
	use "$data_dir/`y'.dta", clear
}


if `y' == 1997 {
	destring parentnumber, replace force
}

if `y' == 2004 | inrange(`y',2006,2009) {
	drop if abi == .
}
isid abi

gen new_est = year1stappeared == `y'


bys parentnumber: egen all_new_est = min(new_est)
	gen new_firm = all_new_est if parentnumber != .
	replace new_firm = new_est if parentnumber == .
	


gen naics2 = int(primarynaicscode/1000000)
	gen naics2desc = "Agriculture, Forestry, Fishing and Hunting" if naics2 == 11
	replace naics2desc = "Mining" if naics2 == 21
	replace naics2desc = "Utilities" if naics2 == 22
	replace naics2desc = "Construction" if naics2 == 23
	replace naics2desc = "Manufacturing" if inrange(naics2, 31, 33)
	replace naics2desc = "Wholesale Trade" if naics2 == 42
	replace naics2desc = "Retail Trade" if inrange(naics2, 44, 45)
	replace naics2desc = "Transportation and Warehousing" if inrange(naics2, 48, 49)
	replace naics2desc = "Information" if naics2 == 51
	replace naics2desc = "Finance and Insurance" if naics2 == 52
	replace naics2desc = "Real Estate and Rental and Leasing" if naics2 == 53
	replace naics2desc = "Professional, Scientific, and Technical Services" if naics2 == 54
	replace naics2desc = "Management of Companies and Enterprises" if naics2 == 55
	replace naics2desc = "Administrative and Support and Waste Management and Remediation Services" if naics2 == 56
	replace naics2desc = "Educational Services" if naics2 == 61
	replace naics2desc = "Health Care and Social Assistance" if naics2 == 62
	replace naics2desc = "Arts, Entertainment, and Recreation" if naics2 == 71
	replace naics2desc = "Accommodation and Food Services" if naics2 == 72
	replace naics2desc = "Other Services (except Public Administration)" if naics2 == 81
	replace naics2desc = "Public Administration" if naics2 == 92
	#delimit ;
	global industries Agriculture "Mining" "Utilities" "Construction" "Manufacturing"
					"Wholesale Trade" "Retail Trade" "Transportation and Warehousing"
					"Information" "Finance and Insurance" "Real Estate"
					"Professional" "Management" "Administrative and Support"
					"Educational Services" "Health Care" "Arts, Entertainment, and Recreation"
					"Accommodation and Food Services" "Other Services" "Public Administration";
	#delimit cr
	
	
gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode == 35620
	replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode == 31080
	replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode == 16980
	replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode == 26420
	replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode == 38060
	replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode == 37980


preserve // Aggregate startup rate over time, IQR for states
	gen statefips = int(fipscode/1000)
	egen tag_state = tag(parentnumber statefips)
		drop if tag_state == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(statefips) fast

	gen sr = new_firm/n_firms
	collapse (mean) sr_mean = sr (p25) sr_p25 = sr (p75) sr_p75 = sr, fast
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/agg`y'.dta", replace
restore
preserve // Aggregate startup rate over time
	egen tag_state = tag(parentnumber)
		drop if tag_state == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, fast

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/agg`y'_sr.dta", replace
restore


preserve // Industry-level startup rate, IQR for CBSAs
	drop if cbsacode == .
	egen tag_indcbsa = tag(parentnumber naics2desc cbsacode)
		drop if tag_indcbsa == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(naics2desc cbsacode) fast
	drop if naics2desc == ""

	gen sr = new_firm/n_firms
	collapse (mean) sr_mean = sr (p25) sr_p25 = sr (p75) sr_p75 = sr, by(naics2desc) fast
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/ind`y'.dta", replace
restore


preserve // Industry-level startup rate
	egen tag_ind = tag(parentnumber naics2desc)
		drop if tag_ind == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(naics2desc) fast
	drop if naics2desc == ""

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/ind`y'_sr.dta", replace
restore


preserve // CBSA-level startup rate, IQR for tracts within that 
	drop if cbsaname == ""
	gen geoid10 = string(fipscode) + string(censustract)
		drop if geoid10 == ".."
		destring geoid10, replace
	egen tag_tract = tag(parentnumber cbsacode geoid10)
		drop if tag_tract == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(cbsacode cbsaname geoid10) fast
	drop if geoid10 == .

	gen sr = new_firm/n_firms
	collapse (mean) sr_mean = sr (p25) sr_p25 = sr (p75) sr_p75 = sr, by(cbsacode cbsaname) fast
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/cbsa`y'.dta", replace
restore

preserve // CBSA-level startup rate, IQR for zipcodes within that 
	drop if cbsaname == ""
	egen tag_zip = tag(parentnumber cbsacode zipcode)
		drop if tag_zip == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(cbsacode cbsaname zipcode) fast
	drop if zipcode == .

	gen sr = new_firm/n_firms
	collapse (mean) sr_mean = sr (p25) sr_p25 = sr (p75) sr_p75 = sr, by(cbsacode cbsaname) fast
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/cbsa`y'_zip.dta", replace
restore

preserve // CBSA-level startup rate
	drop if cbsaname == ""
	egen tag_cbsa = tag(parentnumber cbsacode)
		drop if tag_cbsa == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(cbsacode cbsaname) fast

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "$proj_dir/processed-data/startup_rates/cbsa`y'_sr.dta", replace
restore

}
*-------------------------------------------------------------------------------
* Aggregate Appending
use "$proj_dir/processed-data/startup_rates/agg1997.dta", clear

forval y = 1999/2021 {
	append using "$proj_dir/processed-data/startup_rates/agg`y'.dta"
}

tempfile aggregate
save `aggregate', replace


use "$proj_dir/processed-data/startup_rates/agg1997_sr.dta", clear

forval y = 1999/2021 {
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

* Note: data quality much worse 1999-2002
drop if year < 2003

#delimit ;

tw (rcap sr_p25 sr_p75 year, lc(edkblue))
   (scatter sr year, msym(O) mc(eltblue))
   (scatter sr_mean year, msym(X) mc(edkblue)),
  legend(order(2 "Startup Rate" 3 "Mean SR Across States" 1 "IQR Across States") r(1))
  ti("Aggregate Startup Rate") xti("Year") yti("")
  xlab(2003(2)2021,labsize(small)) ylab(0(0.02)0.08,labsize(small));
graph export "$proj_dir/output/startup_ts_agg.png", replace as(png);

#delimit cr

* By Industry // ---------------------------------------------------------------

use "$proj_dir/processed-data/startup_rates/ind1997.dta", clear

forval y = 1999/2021 {
	append using "$proj_dir/processed-data/startup_rates/ind`y'.dta"
}

tempfile industry
save `industry', replace


use "$proj_dir/processed-data/startup_rates/ind1997_sr.dta", clear

forval y = 1999/2021 {
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

* Note: data quality much worse 1999-2002
drop if year < 2003

foreach ind of global industries {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(naics2desc,"`ind'") > 0, lc(edkblue))
	   (scatter sr year if strpos(naics2desc,"`ind'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(naics2desc,"`ind'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across CBSAs" 1 "IQR Across CBSAs") r(1))
	  ti("`ind' Startup Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr

}

* By CBSA (tracts)

use "$proj_dir/processed-data/startup_rates/cbsa1997.dta", clear

forval y = 1999/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'.dta"
}

tempfile metros
save `metros', replace


use "$proj_dir/processed-data/startup_rates/cbsa1997_sr.dta", clear

forval y = 1999/2021 {
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

* Note: data quality much worse 1999-2002
drop if year < 2003

foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (scatter sr year if strpos(cbsaname,"`city'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(cbsaname,"`city'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across Tracts" 1 "IQR Across Tracts") r(1))
	  ti("`city' Startup Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr

}

* By CBSA (zipcodes)

use "$proj_dir/processed-data/startup_rates/cbsa1997_zip.dta", clear

forval y = 1999/2021 {
	append using "$proj_dir/processed-data/startup_rates/cbsa`y'_zip.dta"
}

tempfile metros
save `metros', replace


use "$proj_dir/processed-data/startup_rates/cbsa1997_sr.dta", clear

forval y = 1999/2021 {
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

* Note: data quality much worse 1999-2002
drop if year < 2003

foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rcap sr_p25 sr_p75 year if strpos(cbsaname,"`city'") > 0, lc(edkblue))
	   (scatter sr year if strpos(cbsaname,"`city'") > 0, msym(O) mc(eltblue))
	   (scatter sr_mean year if strpos(cbsaname,"`city'") > 0, msym(X) mc(edkblue)),
	  legend(order(2 "Startup Rate" 3 "Mean SR Across Zipcodes" 1 "IQR Across Zipcodes") r(1))
	  ti("`city' Startup Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/startup_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr

}




