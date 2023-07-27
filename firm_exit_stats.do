/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

firm_exit_stats.do

*/


global data_dir "/Volumes/Seagate Por/infogroup in Dropbox DevBanks/_original_data/"
global proj_dir "/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism"

cap mkdir "$proj_dir/processed-data/exit_rates/"

#delimit ;
local varlist "company employeesize5location employeesize6corporate modeledemployeesize
				parentnumber callstatuscode teleresearchupdatedate year1stappeared
				cbsacode fipscode censustract zipcode primarynaicscode";
#delimit cr
/*
forval y = 1997/2021 {
	use abi `varlist' using "$data_dir/`y'.dta", clear
	ren * *`y'
	ren abi`y' abi
	drop if abi == .
	
	if `y' == 2004 | inrange(`y',2006,2009) {
		drop if abi == .
	}

	isid abi
	
	local yp = `y' + 1
	
	if `yp' == 2007 {
		preserve
			use "$data_dir/`yp'.dta", clear
			drop if abi == .
			tempfile new`yp'
			save `new`yp'', replace
		restore
		
		merge 1:1 abi using `new`yp'', keepus(`varlist')
	}

	if `yp' == 2022 {
		merge 1:1 abi using "$data_dir/`yp'.dta"
	}
	
	if !inlist(`yp',2007,2022) {
		merge 1:1 abi using "$data_dir/`yp'.dta", keepus(`varlist')
	}
	
	
	ren * *`yp'
	ren abi`yp' abi
	ren *`y'`yp' *`y'
	
	
	gen est_exit = _merge == 1
	bys parentnumber`y': egen all_close = min(est_exit)
		gen firm_exit = all_close if parentnumber`y' != .
		replace firm_exit = est_exit if parentnumber`y' == .
		
	gen est_age = `y' - year1stappeared`y'
		bys parentnumber`y': egen max_est_age = max(est_age)
		gen firm_age = max_est_age if parentnumber`y' != .
		replace firm_age = est_age if parentnumber`y' == .
		replace firm_age = 11 if firm_age >= 11
	
	
	gen naics2 = int(primarynaicscode`y'/1000000)
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


	gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode`y' == 35620
		replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode`y' == 31080
		replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode`y' == 16980
		replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode`y' == 26420
		replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode`y' == 38060
		replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode`y' == 37980
		
	/*
	preserve // Aggregate startup rate over time
		egen tagged = tag(parentnumber`y')
			drop if tagged == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(firm_age) fast

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/agg`y'_er.dta", replace
	restore	*/
	preserve // Aggregate exit rate over time, IQR for states
		gen statefips = int(fipscode`y'/1000)
		egen tag_state = tag(parentnumber`y' statefips)
			drop if tag_state == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(statefips firm_age) fast

		gen er = firm_exit/n_firms
		collapse (mean) er_mean = er (p25) er_p25 = er (p75) er_p75 = er, by(firm_age) fast
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/agg`y'.dta", replace
	restore
		/*
	preserve // Industry-level startup rate
		egen tag_ind = tag(parentnumber`y' naics2desc)
			drop if tag_ind == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(naics2desc firm_age) fast
		drop if naics2desc == ""

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/ind`y'_er.dta", replace
	restore

	preserve // Industry-level startup rate, IQR for CBSAs
		drop if cbsacode`y' == .
		egen tag_indcbsa = tag(parentnumber`y' naics2desc cbsacode`y')
			drop if tag_indcbsa == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(naics2desc cbsacode`y' firm_age) fast
		drop if naics2desc == ""

		gen er = firm_exit/n_firms
		collapse (mean) er_mean = er (p25) er_p25 = er (p75) er_p75 = er, by(naics2desc firm_age) fast
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/ind`y'.dta", replace
	restore	
	
	preserve // CBSA-level startup rate
		drop if cbsaname == ""
		egen tag_cbsa = tag(parentnumber`y' cbsacode`y')
			drop if tag_cbsa == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(cbsacode`y' cbsaname firm_age) fast

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/cbsa`y'_er.dta", replace
	restore

	preserve // CBSA-level startup rate, IQR for zipcodes within that 
		drop if cbsaname == ""
		egen tag_zip = tag(parentnumber`y' cbsacode`y' zipcode`y')
			drop if tag_zip == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(cbsacode`y' cbsaname zipcode`y' firm_age) fast
		drop if zipcode == .

		gen er = firm_exit/n_firms
		collapse (mean) er_mean = er (p25) er_p25 = er (p75) er_p75 = er, by(cbsacode`y' cbsaname firm_age) fast
		gen year = `y'
		
		save "$proj_dir/processed-data/exit_rates/cbsa`y'.dta", replace
	restore*/


}
*/
*-------------------------------------------------------------------------------
/*
* Aggregate Appending
use "$proj_dir/processed-data/exit_rates/agg1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/agg`y'.dta"
}

tempfile aggregate
save `aggregate', replace


use "$proj_dir/processed-data/exit_rates/agg1997_er.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/agg`y'_er.dta"
}

merge 1:1 year firm_age using `aggregate', assert(3)


gsort year -firm_age

gen agedist_y1 = 0 if firm_age == 11
gen agedist_y2 = n_firms if firm_age == 11
forval ii = 0/10 {
	replace agedist_y1 = agedist_y2[_n-1] if firm_age == 10-`ii'
	replace agedist_y2 = agedist_y1 + n_firms if firm_age == 10-`ii'
	br year n_firms firm_age agedist_y1 agedist_y2
}

replace agedist_y1 = agedist_y1/1000000
replace agedist_y2 = agedist_y2/1000000

	#delimit ;
	
	tw (rarea agedist_y1 agedist_y2 year if firm_age == 0, col(erose))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 1, col(eltgreen))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 2, col(eltblue))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 3, col(emidblue))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 4, col(edkblue))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 5, col(dknavy))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 6, col(bluishgray))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 7, col(gs12))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 8, col(gs10))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 9, col(gs8))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 10, col(gs6))
	   (rarea agedist_y1 agedist_y2 year if firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("Aggregate Firm Age Distribution") xti("Year") yti("# of Firms (millions)")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agedist_ts_agg.png", replace as(png);
	
	#delimit cr
	
	
	
bys year: egen tot_firms = max(agedist_y2)

gen agefrac_y1 = agedist_y1/tot_firms*100
gen agefrac_y2 = agedist_y2/tot_firms*100


	#delimit ;
	
	tw (rarea agefrac_y1 agefrac_y2 year if firm_age == 0, col(erose))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 1, col(eltgreen))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 2, col(eltblue))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 3, col(emidblue))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 4, col(edkblue))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 5, col(dknavy))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 6, col(bluishgray))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 7, col(gs12))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 8, col(gs10))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 9, col(gs8))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 10, col(gs6))
	   (rarea agefrac_y1 agefrac_y2 year if firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("Aggregate Firm Age Distribution") xti("Year") yti("% of Firms")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agefrac_ts_agg.png", replace as(png);
	
	#delimit cr

	#delimit ;
	* Compare firms ages 0, 2, and 6;
	replace year = year + 0.1 if firm_age == 2;
	replace year = year + 0.2 if firm_age == 6;
	
	tw (rcap er_p25 er_p75 year if firm_age == 6, lc(edkblue))
	   (scatter er year if firm_age == 6, msym(O) mc(eltblue))
	   (scatter er_mean year if firm_age == 6, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if firm_age == 2, lc(dkorange))
	   (scatter er year if firm_age == 2, msym(O) mc(sand))
	   (scatter er_mean year if firm_age == 2, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if firm_age == 0, lc(cranberry))
	   (scatter er year if firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 2)" 2 "Exit Rate (Age 6)"
				   9 "Mean ER Across CBSAs" 7 "IQR Across CBSAs") r(2))
	  ti("Aggregate Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-6_ts_agg.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 2;
	replace year = year - 0.2 if firm_age == 6;
	
	
	* Compare firms ages 0, 6, and 11;
	replace year = year + 0.1 if firm_age == 6;
	replace year = year + 0.2 if firm_age == 11;
	
	tw (rcap er_p25 er_p75 year if firm_age == 11, lc(edkblue))
	   (scatter er year if firm_age == 11, msym(O) mc(eltblue))
	   (scatter er_mean year if firm_age == 11, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if firm_age == 6, lc(dkorange))
	   (scatter er year if firm_age == 6, msym(O) mc(sand))
	   (scatter er_mean year if firm_age == 6, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if firm_age == 0, lc(cranberry))
	   (scatter er year if firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 6)" 2 "Exit Rate (Age 11+)"
				   9 "Mean ER Across CBSAs" 7 "IQR Across CBSAs") r(2))
	  ti("Aggregate Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-11_ts_agg.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 6;
	replace year = year - 0.2 if firm_age == 11;
	
	#delimit cr
	

* By Industry // ---------------------------------------------------------------

use "$proj_dir/processed-data/exit_rates/ind1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/ind`y'.dta"
}

tempfile industry
save `industry', replace


use "$proj_dir/processed-data/exit_rates/ind1997_er.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/ind`y'_er.dta"
}

merge 1:1 year naics2 naics2desc firm_age using `industry', assert(3)

gsort year naics2desc -firm_age

gen agedist_y1 = 0 if firm_age == 11
gen agedist_y2 = n_firms if firm_age == 11
forval ii = 0/10 {
	replace agedist_y1 = agedist_y2[_n-1] if firm_age == 10-`ii'
	replace agedist_y2 = agedist_y1 + n_firms if firm_age == 10-`ii'
	br year naics2desc n_firms firm_age agedist_y1 agedist_y2
}


replace agedist_y1 = agedist_y1/1000
replace agedist_y2 = agedist_y2/1000

foreach ind of global industries {
	#delimit ;
	
	tw (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 0, col(erose))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 1, col(eltgreen))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 2, col(eltblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 3, col(emidblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 4, col(edkblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 5, col(dknavy))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 6, col(bluishgray))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 7, col(gs12))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 8, col(gs10))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 9, col(gs8))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 10, col(gs6))
	   (rarea agedist_y1 agedist_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("`ind' Firm Age Distribution") xti("Year") yti("# of Firms (thousands)")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agedist_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr
}

bys year naics2desc: egen tot_firms = max(agedist_y2)

gen agefrac_y1 = agedist_y1/tot_firms*100
gen agefrac_y2 = agedist_y2/tot_firms*100

foreach ind of global industries {
	#delimit ;
	
	tw (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 0, col(erose))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 1, col(eltgreen))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 2, col(eltblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 3, col(emidblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 4, col(edkblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 5, col(dknavy))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 6, col(bluishgray))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 7, col(gs12))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 8, col(gs10))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 9, col(gs8))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 10, col(gs6))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(naics2desc,"`ind'")==1 & firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("`ind' Firm Age Distribution") xti("Year") yti("% of Firms")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agefrac_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr
}



foreach ind of global industries {
	#delimit ;
	* Compare firms age 1 and 2;
	replace year = year + 0.15 if firm_age == 2;
	
	tw (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, lc(edkblue))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 1, lc(dkgreen))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 1, msym(O) mc(eltgreen))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 1, msym(X) mc(dkgreen)),
	  legend(order(5 "Exit Rate (Age 1)" 2 "Exit Rate (Age 2)"
				   6 "Mean ER Across CBSAs" 4 "IQR Across CBSAs") r(2))
	  ti("`ind' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age1-2_ts_ind-`ind'.png", replace as(png);
	
	replace year = year - 0.15 if firm_age == 2;
	
	* Compare firms ages 0, 2, and 6;
	replace year = year + 0.1 if firm_age == 2;
	replace year = year + 0.2 if firm_age == 6;
	
	tw (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, lc(edkblue))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, lc(dkorange))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, msym(O) mc(sand))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 2, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 2)" 2 "Exit Rate (Age 6)"
				   9 "Mean ER Across CBSAs" 7 "IQR Across CBSAs") r(2))
	  ti("`ind' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-6_ts_ind-`ind'.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 2;
	replace year = year - 0.2 if firm_age == 6;
	
	
	* Compare firms ages 0, 6, and 11;
	replace year = year + 0.1 if firm_age == 6;
	replace year = year + 0.2 if firm_age == 11;
	
	tw (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, lc(edkblue))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, lc(dkorange))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(O) mc(sand))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 6)" 2 "Exit Rate (Age 11)"
				   9 "Mean ER Across CBSAs" 7 "IQR Across CBSAs") r(2))
	  ti("`ind' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-11_ts_ind-`ind'.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 6;
	replace year = year - 0.2 if firm_age == 11;
	
	
	
	tw (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(naics2desc,"`ind'")==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(2 "Exit Rate (Age 0)" 3 "Mean ER Across CBSAs" 1 "IQR Across CBSAs") r(1))
	  ti("`ind' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0_ts_ind-`ind'.png", replace as(png);
	
	#delimit cr
}


* Industry Distribution Conditional on Firm Age -------------------------------


use "$proj_dir/processed-data/exit_rates/ind2003.dta", clear

forval y = 2004/2021 {
	append using "$proj_dir/processed-data/exit_rates/ind`y'.dta"
}

tempfile industry
save `industry', replace


use "$proj_dir/processed-data/exit_rates/ind2003_er.dta", clear

forval y = 2004/2021 {
	append using "$proj_dir/processed-data/exit_rates/ind`y'_er.dta"
}



	gen naics2 = "11" if naics2desc == "Agriculture, Forestry, Fishing and Hunting"
		replace naics2 = "21" if naics2desc == "Mining"
		replace naics2 = "22" if naics2desc == "Utilities"
		replace naics2 = "23" if naics2desc == "Construction"
		replace naics2 = "31-33" if naics2desc == "Manufacturing"
		replace naics2 = "42" if naics2desc == "Wholesale Trade"
		replace naics2 = "44-45" if naics2desc == "Retail Trade"
		replace naics2 = "48-49" if naics2desc == "Transportation and Warehousing"
		replace naics2 = "51" if naics2desc == "Information"
		replace naics2 = "52" if naics2desc == "Finance and Insurance"
		replace naics2 = "53" if naics2desc == "Real Estate and Rental and Leasing"
		replace naics2 = "54" if naics2desc == "Professional, Scientific, and Technical Services"
		replace naics2 = "55" if naics2desc == "Management of Companies and Enterprises"
		replace naics2 = "56" if naics2desc == "Administrative and Support and Waste Management and Remediation Services"
		replace naics2 = "61" if naics2desc == "Educational Services"
		replace naics2 = "62" if naics2desc == "Health Care and Social Assistance"
		replace naics2 = "71" if naics2desc == "Arts, Entertainment, and Recreation"
		replace naics2 = "72" if naics2desc == "Accommodation and Food Services"
		replace naics2 = "81" if naics2desc == "Other Services (except Public Administration)"
		replace naics2 = "92" if naics2desc == "Public Administration"
		#delimit ;
		global industries Agriculture "Mining" "Utilities" "Construction" "Manufacturing"
						"Wholesale Trade" "Retail Trade" "Transportation and Warehousing"
						"Information" "Finance and Insurance" "Real Estate"
						"Professional" "Management" "Administrative and Support"
						"Educational Services" "Health Care" "Arts, Entertainment, and Recreation"
						"Accommodation and Food Services" "Other Services" "Public Administration";
		#delimit cr
		

merge 1:1 year naics2desc firm_age using `industry', assert(3)

gsort year firm_age -naics2

gen inddist_y1 = 0 if naics2 == "92"
gen inddist_y2 = n_firms if naics2 == "92"
foreach i in "81" "72" "71" "62" "61" "56" "55" "54" "53" "52" "51" "48-49" ///
				"44-45" "42" "31-33" "23" "22" "21" "11" {
	replace inddist_y1 = inddist_y2[_n-1] if naics2 == "`i'"
	replace inddist_y2 = inddist_y1 + n_firms if naics2 == "`i'"
	br year naics2desc n_firms firm_age inddist_y1 inddist_y2
	pause
}


replace inddist_y1 = inddist_y1/1000
replace inddist_y2 = inddist_y2/1000

forval a = 0/11 {
	if `a' == 11 {
		local aname "11+"
	}
	else {
		local aname "`a'"
	}
	
	#delimit ;
	
	tw (rarea inddist_y1 inddist_y2 year if naics2=="11" & firm_age == `a', col(sandb))
	   (rarea inddist_y1 inddist_y2 year if naics2=="21" & firm_age == `a', col(sand))
	   (rarea inddist_y1 inddist_y2 year if naics2=="22" & firm_age == `a', col(erose))
	   (rarea inddist_y1 inddist_y2 year if naics2=="23" & firm_age == `a', col(brown))
	   (rarea inddist_y1 inddist_y2 year if naics2=="31-33" & firm_age == `a', col(sienna))
	   (rarea inddist_y1 inddist_y2 year if naics2=="42" & firm_age == `a', col(olive_teal))
	   (rarea inddist_y1 inddist_y2 year if naics2=="44-45" & firm_age == `a', col(eltgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="48-49" & firm_age == `a', col(forest_green))
	   (rarea inddist_y1 inddist_y2 year if naics2=="51" & firm_age == `a', col(dkgreen))
	   (rarea inddist_y1 inddist_y2 year if naics2=="52" & firm_age == `a', col(eltblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="53" & firm_age == `a', col(ebblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="54" & firm_age == `a', col(emidblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="55" & firm_age == `a', col(edkblue))
	   (rarea inddist_y1 inddist_y2 year if naics2=="56" & firm_age == `a', col(dknavy))
	   (rarea inddist_y1 inddist_y2 year if naics2=="61" & firm_age == `a', col(bluishgray))
	   (rarea inddist_y1 inddist_y2 year if naics2=="62" & firm_age == `a', col(gs12))
	   (rarea inddist_y1 inddist_y2 year if naics2=="71" & firm_age == `a', col(gs10))
	   (rarea inddist_y1 inddist_y2 year if naics2=="72" & firm_age == `a', col(gs8))
	   (rarea inddist_y1 inddist_y2 year if naics2=="81" & firm_age == `a', col(gs6))
	   (rarea inddist_y1 inddist_y2 year if naics2=="92" & firm_age == `a', col(gs4)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs" 19 "Public") r(5))
	  ti("Industry Distribution of Firms (Age `aname')") xti("Year") yti("# of Firms (thousands)" " ")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_inddist_ts_age-`aname'.png", replace as(png);
	
	#delimit cr
}

bys year firm_age: egen tot_firms = max(inddist_y2)

gen indfrac_y1 = inddist_y1/tot_firms*100
gen indfrac_y2 = inddist_y2/tot_firms*100

forval a = 0/11 {
	if `a' == 11 {
		local aname "11+"
	}
	else {
		local aname "`a'"
	}
	
	#delimit ;
	
	tw (rarea indfrac_y1 indfrac_y2 year if naics2=="11" & firm_age == `a', col(sandb))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="21" & firm_age == `a', col(sand))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="22" & firm_age == `a', col(erose))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="23" & firm_age == `a', col(brown))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="31-33" & firm_age == `a', col(sienna))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="42" & firm_age == `a', col(olive_teal))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="44-45" & firm_age == `a', col(eltgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="48-49" & firm_age == `a', col(forest_green))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="51" & firm_age == `a', col(dkgreen))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="52" & firm_age == `a', col(eltblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="53" & firm_age == `a', col(ebblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="54" & firm_age == `a', col(emidblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="55" & firm_age == `a', col(edkblue))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="56" & firm_age == `a', col(dknavy))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="61" & firm_age == `a', col(bluishgray))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="62" & firm_age == `a', col(gs12))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="71" & firm_age == `a', col(gs10))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="72" & firm_age == `a', col(gs8))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="81" & firm_age == `a', col(gs6))
	   (rarea indfrac_y1 indfrac_y2 year if naics2=="92" & firm_age == `a', col(gs4)),
	  legend(order(1 "Agriculture" 2 "Mining" 3 "Utilities" 4 "Construction"
					5 "Manufacturing" 6 "Wholesale" 7 "Retail" 8 "Transportation"
					9 "Information" 10  "Finance" 10 "Real Estate" 11 "Professional"
					12 "Management" 13 "Administrative" 14 "Education" 15 "Health Care"
					16 "Arts" 17 "Accommodation" 18 "Other Svcs" 19 "Public") r(5))
	  ti("Industry Distribution of Firms (Age `aname')") xti("Year") yti("% of Firms" " ")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_indfrac_ts_age-`aname'.png", replace as(png);
	
	#delimit cr
}
*/

* Exit Rate Heterogeneity Across States

#delimit ;
	global industries Agriculture "Mining" "Utilities" "Construction" "Manufacturing"
					"Wholesale Trade" "Retail Trade" "Transportation and Warehousing"
					"Information" "Finance and Insurance" "Real Estate"
					"Professional" "Management" "Administrative and Support"
					"Educational Services" "Health Care" "Arts, Entertainment, and Recreation"
					"Accommodation and Food Services" "Other Services" "Public Administration";
#delimit cr


use "$proj_dir/processed-data/exit_rates/ind-state2003.dta", clear

forval y = 2004/2021 {
	append using "$proj_dir/processed-data/exit_rates/ind-state`y'.dta"
}

drop if naics2desc == ""
gen er = firm_exit / n_firms
collapse (sum) firm_exit n_firms (p25) er_p25 = er ///
		 (mean) er_mean = er (p75) er_p75 = er, by(year firm_age naics2desc)
gen er = firm_exit / n_firms


foreach ind of global industries {
	#delimit ;
	
	* Compare firms ages 0, 6, and 11;
	replace year = year + 0.1 if firm_age == 6;
	replace year = year + 0.2 if firm_age == 11;
	
	tw (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, lc(edkblue))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 11, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, lc(dkorange))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(O) mc(sand))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 6, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(naics2desc,"`ind'") ==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 6)" 2 "Exit Rate (Age 11)"
				   9 "Mean ER Across States" 7 "IQR Across States") r(2))
	  ti("`ind' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-11_ts_ind-`ind'.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 6;
	replace year = year - 0.2 if firm_age == 11;
	
	#delimit cr
}




/*
* By CBSA (tracts)

use "$proj_dir/processed-data/exit_rates/cbsa1997.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/cbsa`y'.dta"
}

tempfile metros
save `metros', replace


use "$proj_dir/processed-data/exit_rates/cbsa1997_er.dta", clear

forval y = 1998/2021 {
	append using "$proj_dir/processed-data/exit_rates/cbsa`y'_er.dta"
}

merge 1:1 year cbsaname firm_age using `metros', assert(3)


gsort year cbsaname -firm_age

gen agedist_y1 = 0 if firm_age == 11
gen agedist_y2 = n_firms if firm_age == 11
forval ii = 0/10 {
	replace agedist_y1 = agedist_y2[_n-1] if firm_age == 10-`ii'
	replace agedist_y2 = agedist_y1 + n_firms if firm_age == 10-`ii'
	br year cbsaname n_firms firm_age agedist_y1 agedist_y2
}

replace agedist_y1 = agedist_y1/1000
replace agedist_y2 = agedist_y2/1000

foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 0, col(erose))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 1, col(eltgreen))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 2, col(eltblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 3, col(emidblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 4, col(edkblue))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 5, col(dknavy))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 6, col(bluishgray))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 7, col(gs12))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 8, col(gs10))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 9, col(gs8))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 10, col(gs6))
	   (rarea agedist_y1 agedist_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("`city' Firm Age Distribution") xti("Year") yti("# of Firms (thousands)")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agedist_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr
}

bys year cbsaname: egen tot_firms = max(agedist_y2)

gen agefrac_y1 = agedist_y1/tot_firms*100
gen agefrac_y2 = agedist_y2/tot_firms*100

foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
	#delimit ;
	
	tw (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 0, col(erose))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 1, col(eltgreen))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 2, col(eltblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 3, col(emidblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 4, col(edkblue))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 5, col(dknavy))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 6, col(bluishgray))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 7, col(gs12))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 8, col(gs10))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 9, col(gs8))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 10, col(gs6))
	   (rarea agefrac_y1 agefrac_y2 year if strpos(cbsaname,"`city'")==1 & firm_age == 11, col(gs4)),
	  legend(order(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "6" 8 "7" 9 "8" 10 "9" 11 "10" 12 "11+") r(3))
	  ti("`city' Firm Age Distribution") xti("Year") yti("% of Firms")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/firm_agefrac_ts_cbsa-`city'.png", replace as(png);
	
	#delimit cr
}





foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia"  {
	#delimit ;
	
	* Compare firms ages 0, 2, and 6;
	replace year = year + 0.1 if firm_age == 2;
	replace year = year + 0.2 if firm_age == 6;
	
	tw (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, lc(edkblue))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 2, lc(dkorange))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 2, msym(O) mc(sand))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 2, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 2)" 2 "Exit Rate (Age 6)"
				   9 "Mean ER Across Zipcodes" 7 "IQR Across Zipcodes") r(2))
	  ti("`city' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-6_ts_cbsa-`city'.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 2;
	replace year = year - 0.2 if firm_age == 6;
	
	
	* Compare firms ages 0, 6, and 11;
	replace year = year + 0.1 if firm_age == 6;
	replace year = year + 0.2 if firm_age == 11;
	
	tw (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 11, lc(edkblue))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 11, msym(O) mc(eltblue))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 11, msym(X) mc(edkblue))
	   (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, lc(dkorange))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, msym(O) mc(sand))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 6, msym(X) mc(dkorange))
	   (rcap er_p25 er_p75 year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, lc(cranberry))
	   (scatter er year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, msym(O) mc(erose))
	   (scatter er_mean year if strpos(cbsaname,"`city'") ==1 & firm_age == 0, msym(X) mc(cranberry)),
	  legend(order(8 "Exit Rate (Age 0)" 5 "Exit Rate (Age 6)" 2 "Exit Rate (Age 11)"
				   9 "Mean ER Across CBSAs" 7 "IQR Across CBSAs") r(2))
	  ti("`city' Exit Rate") xti("Year") yti("")
	  xlab(2003(2)2021,labsize(small)) ylab(,labsize(small));
	graph export "$proj_dir/output/exit_age0-11_ts_cbsa-`city'.png", replace as(png);
	
	replace year = year - 0.1 if firm_age == 6;
	replace year = year - 0.2 if firm_age == 11;
	
	
	#delimit cr
}

*/
