/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

firm_exit_stats_cluster.do

*/


#delimit ;
local varlist "company employeesize5location employeesize6corporate modeledemployeesize
				parentnumber callstatuscode teleresearchupdatedate year1stappeared
				cbsacode fipscode censustract zipcode primarynaicscode";
#delimit cr

forval y = 2003/2021 {

	local yp = `y' + 1

	zipuse "`yp'.dta.zip", clear
	drop if abi == .
	tempfile temp`yp'
	save `temp`yp'', replace


	zipuse abi `varlist' using "`y'.dta.zip", clear
	ren * *`y'
	ren abi`y' abi
	drop if abi == .
	sort abi
	
	isid abi
	
	if `yp' < 2022 {
	merge 1:1 abi using `temp`yp'', keepus(`varlist')
	}
	if `yp' == 2022 {
	merge 1:1 abi using `temp`yp''
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
		
	cap mkdir "exit_rates"

	/*
	preserve // Aggregate exit rate over time
		egen tagged = tag(parentnumber`y')
			drop if tagged == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(firm_age) fast

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "exit_rates/agg`y'_er.dta", replace
	restore	
	preserve // Aggregate exit rate over time, IQR for states
		gen statefips = int(fipscode`y'/1000)
		egen tag_state = tag(parentnumber`y' statefips)
			drop if tag_state == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(statefips firm_age) fast

		gen er = firm_exit/n_firms
		collapse (mean) er_mean = er (p25) er_p25 = er (p75) er_p75 = er, by(firm_age) fast
		gen year = `y'
		
		save "exit_rates/agg`y'.dta", replace
	restore
	*/
	
	preserve // Exiting and total # of firms, by state and sector
		gen statefips = int(fipscode`y'/1000)
		egen tag_state = tag(parentnumber`y' statefips)
			drop if tag_state == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(statefips firm_age naics2desc) fast
		gen year = `y'
		
		save "exit_rates/ind-state`y'.dta", replace
	restore
	
	/*
	preserve // Industry-level startup rate
		egen tag_ind = tag(parentnumber`y' naics2desc)
			drop if tag_ind == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(naics2desc firm_age) fast
		drop if naics2desc == ""

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "exit_rates/ind`y'_er.dta", replace
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
		
		save "exit_rates/ind`y'.dta", replace
	restore	
	
	preserve // CBSA-level exit rate
		drop if cbsaname == ""
		egen tag_cbsa = tag(parentnumber`y' cbsacode`y')
			drop if tag_cbsa == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(cbsacode`y' cbsaname firm_age) fast

		gen er = firm_exit/n_firms
		gen year = `y'
		
		save "exit_rates/cbsa`y'_er.dta", replace
	restore

	preserve // CBSA-level exit rate, IQR for zipcodes within that 
		drop if cbsaname == ""
		egen tag_zip = tag(parentnumber`y' cbsacode`y' zipcode`y')
			drop if tag_zip == 0 & parentnumber`y' != .
			
		collapse (sum) firm_exit (count) n_firms = abi, by(cbsacode`y' cbsaname zipcode`y' firm_age) fast
		drop if zipcode == .

		gen er = firm_exit/n_firms
		collapse (mean) er_mean = er (p25) er_p25 = er (p75) er_p75 = er, by(cbsacode`y' cbsaname firm_age) fast
		gen year = `y'
		
		save "exit_rates/cbsa`y'.dta", replace
	restore

*/

}
