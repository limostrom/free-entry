/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

startup_stats.do

*/

forval y = 1997/2022 {

	zipuse "`y'.dta.zip", clear


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
	
/*

preserve // Aggregate startup rate over time, IQR for states
	gen statefips = int(fipscode/1000)
	egen tag_state = tag(parentnumber statefips)
		drop if tag_state == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(statefips) fast

	gen sr = new_firm/n_firms
	collapse (mean) sr_mean = sr (p25) sr_p25 = sr (p75) sr_p75 = sr, fast
	gen year = `y'
	
	save "startup_rates/agg`y'.dta", replace
restore
preserve // Aggregate startup rate over time
	egen tag_state = tag(parentnumber)
		drop if tag_state == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, fast

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "startup_rates/agg`y'_sr.dta", replace
restore


preserve // Industry-by-CBSA-level startup rate
	gen nonmetro = inlist(cbsacode, ., 0)
	assert cbsacode > 100 if nonmetro == 0
	gen statefips = int(fipscode/1000)
	replace cbsacode = statefips if nonmetro == 1
	egen tag_indcbsa = tag(parentnumber naics2desc cbsacode nonmetro)
		drop if tag_indcbsa == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(naics2desc cbsacode nonmetro) fast
	drop if naics2desc == ""

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "startup_rates/ind-cbsa`y'.dta", replace
restore
*/

preserve // Industry-by-State-level startup rate
	gen statefips = int(fipscode/1000)
	egen tag_indst = tag(parentnumber naics2desc statefips)
		drop if tag_indst == 0 & parentnumber != .
		
	collapse (sum) new_firm (count) n_firms = abi, by(naics2desc state) fast
	drop if naics2desc == ""

	gen sr = new_firm/n_firms
	gen year = `y'
	
	save "startup_rates/ind-state`y'.dta", replace
restore


}
