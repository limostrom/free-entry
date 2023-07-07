/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

estab_exit_stats.do

*/


global data_dir "/Volumes/Seagate Por/infogroup in Dropbox DevBanks/_original_data/"
global proj_dir "/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism"

cap mkdir "$proj_dir/output"
cap mkdir "$proj_dir/output/gphs"

#delimit ;
local varlist "company employeesize5location employeesize6corporate modeledemployeesize
				parentnumber callstatuscode teleresearchupdatedate
				year1stappeared yearestablished cbsacode fipscode censustract
				primarynaicscode primarysiccode";
#delimit cr

/*
*************
* 2005-2006 *
*************

use abi `varlist' using "$data_dir/2005.dta", clear
ren * *05
ren abi05 abi

isid abi


merge 1:1 abi using "$data_dir/2006.dta", keepus(`varlist')
ren * *06
ren abi06 abi
ren *0506 *05



* Establishment Exits (i.e. just that location closed)
gen est_exit = _merge == 1
gen est_entry = _merge == 2

gen exists2005 = inlist(_merge, 1, 3)

gen est_age = 2005 - year1stappeared05

gen naics2 = int(primarynaicscode05/1000000)
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

gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode05 == 35620
	replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode05 == 31080
	replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode05 == 16980
	replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode05 == 26420
	replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode05 == 38060
	replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode05 == 37980
	
preserve // aggregate exit rates
	collapse (sum) est_exit est_entry exists2005, fast
	gen est_exit_rate = est_exit/exists2005
	gen est_entry_rate = est_entry/exists2005
	export delimited "$proj_dir/output/est_agg_entry_exit_2005.csv", replace
restore

preserve // exit rates by firm age
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2005, by(est_age) fast
	gen est_exit_rate = est_exit/exists2005
	egen exists_tot = sum(exists2005)
		replace exists2005 = exists_tot if est_age == "Total"
		drop exists_tot
	gen est_entry_rate = est_entry/exists2005
	graph bar est_exit_rate if est_age != "Total", over(est_age) bar(1,col(edkblue)) ///
		ti("Aggregate (2005-2006)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments") ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2005.png", replace as(png)
	export delimited "$proj_dir/output/est_age_exit_2005.csv", replace
restore

preserve // exit rates by firm age and CBSA
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2005, by(est_age cbsaname cbsacode05) fast
	drop if cbsaname == ""
	gen est_exit_rate = est_exit/exists2005
	gen est_entry_rate = est_entry/exists2005
	foreach city in "New York" /*"Los Angeles"*/ "Chicago" /*"Houston" "Phoenix"*/ "Philadelphia" {
		graph bar est_exit_rate if strpos(cbsaname,"`city'") > 0, over(est_age) bar(1,col(edkblue)) ///
				ti("`city' (2005-2006)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments") ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2005-`city'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2005.csv", replace
restore



preserve // exit rates by firm age and industry (NAICS 2-digit)
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2005, by(est_age naics2desc) fast
	drop if naics2desc == ""
	gen est_exit_rate = est_exit/exists2005
	gen est_entry_rate = est_entry/exists2005
	foreach ind in $industries {
		dis "`ind'"
		#delimit ;
		graph bar est_exit_rate if strpos(naics2desc,"`ind'") ==1, over(est_age) bar(1,col(edkblue))
				ti("`ind' (2005-2006)") subti("Firm Age",pos(6))
				yti("Exit Rate for Establishments") ylab(0(0.05)0.35);
		graph export "$proj_dir/output/est_age_exit_2005-`ind'.png", replace as(png);
		#delimit cr
	}
	export delimited "$proj_dir/output/est_age_ind_exit_2005.csv", replace
restore
*/


*************
* 2011-2012 *
*************

use abi `varlist' using "$data_dir/2011.dta", clear
ren * *11
ren abi11 abi

isid abi


merge 1:1 abi using "$data_dir/2012.dta", keepus(`varlist')
ren * *12
ren abi12 abi
ren *1112 *11



* Establishment Exits (i.e. just that location closed)
gen est_exit = _merge == 1
gen est_entry = _merge == 2

gen exists2011 = inlist(_merge, 1, 3)

gen est_age = 2011 - year1stappeared11

gen naics2 = int(primarynaicscode11/1000000)
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


gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode11 == 35620
	replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode11 == 31080
	replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode11 == 16980
	replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode11 == 26420
	replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode11 == 38060
	replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode11 == 37980
	
preserve // aggregate exit rates
	collapse (sum) est_exit est_entry exists2011, fast
	gen est_exit_rate = est_exit/exists2011
	gen est_entry_rate = est_entry/exists2011
	export delimited "$proj_dir/output/est_agg_entry_exit_2011.csv", replace
restore

preserve // exit rates by firm age
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2011, by(est_age) fast
	gen est_exit_rate = est_exit/exists2011
	egen exists_tot = sum(exists2011)
		replace exists2011 = exists_tot if est_age == "Total"
		drop exists_tot
	gen est_entry_rate = est_entry/exists2011
	graph bar est_exit_rate if est_age != "Total", over(est_age)  bar(1,col(edkblue)) ///
		ti("Aggregate (2011-2012)") subti("Firm Age",pos(6)) ///
		yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2011.png", replace as(png)
	export delimited "$proj_dir/output/est_age_exit_2011.csv", replace
restore

preserve // exit rates by firm age and CBSA
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2011, by(est_age cbsaname cbsacode11) fast
	drop if cbsaname == ""
	gen est_exit_rate = est_exit/exists2011
	gen est_entry_rate = est_entry/exists2011
	foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
		graph bar est_exit_rate if strpos(cbsaname,"`city'") > 0, over(est_age) bar(1,col(edkblue)) ///
				ti("`city' (2011-2012)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2011-`city'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2011.csv", replace
restore



preserve // exit rates by firm age and industry (NAICS 2-digit)
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2011, by(est_age naics2desc) fast
	drop if naics2desc == ""
	gen est_exit_rate = est_exit/exists2011
	gen est_entry_rate = est_entry/exists2011
	foreach ind of global industries {
		graph bar est_exit_rate if strpos(naics2desc,"`ind'") ==1, over(est_age) bar(1,col(edkblue)) ///
				ti("`ind' (2011-2012)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2011-`ind'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2011.csv", replace
restore





*************
* 2018-2019 *
*************

use abi `varlist' using "$data_dir/2018.dta", clear
ren * *18
ren abi18 abi

isid abi


merge 1:1 abi using "$data_dir/2019.dta", keepus(`varlist')
ren * *19
ren abi19 abi
ren *1819 *18



* Establishment Exits (i.e. just that location closed)
gen est_exit = _merge == 1
gen est_entry = _merge == 2

gen exists2018 = inlist(_merge, 1, 3)

gen est_age = 2018 - year1stappeared18

gen naics2 = int(primarynaicscode18/1000000)
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


gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode18 == 35620
	replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode18 == 31080
	replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode18 == 16980
	replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode18 == 26420
	replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode18 == 38060
	replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode18 == 37980
	
preserve // aggregate exit rates
	collapse (sum) est_exit est_entry exists2018, fast
	gen est_exit_rate = est_exit/exists2018
	gen est_entry_rate = est_entry/exists2018
	export delimited "$proj_dir/output/est_agg_entry_exit_2018.csv", replace
restore

preserve // exit rates by firm age
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2018, by(est_age) fast
	gen est_exit_rate = est_exit/exists2018
	egen exists_tot = sum(exists2018)
		replace exists2018 = exists_tot if est_age == "Total"
		drop exists_tot
	gen est_entry_rate = est_entry/exists2018
	graph bar est_exit_rate if est_age != "Total", over(est_age)  bar(1,col(edkblue)) ///
		ti("Aggregate (2018-2019)") subti("Firm Age",pos(6)) ///
		yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2018.png", replace as(png)
	export delimited "$proj_dir/output/est_age_exit_2018.csv", replace
restore

preserve // exit rates by firm age and CBSA
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2018, by(est_age cbsaname cbsacode18) fast
	drop if cbsaname == ""
	gen est_exit_rate = est_exit/exists2018
	gen est_entry_rate = est_entry/exists2018
	foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
		graph bar est_exit_rate if strpos(cbsaname,"`city'") > 0, over(est_age) bar(1,col(edkblue)) ///
				ti("`city' (2018-2019)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2018-`city'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2018.csv", replace
restore



preserve // exit rates by firm age and industry (NAICS 2-digit)
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2018, by(est_age naics2desc) fast
	drop if naics2desc == ""
	gen est_exit_rate = est_exit/exists2018
	gen est_entry_rate = est_entry/exists2018
	foreach ind of global industries {
		graph bar est_exit_rate if strpos(naics2desc,"`ind'") ==1, over(est_age) bar(1,col(edkblue)) ///
				ti("`ind' (2018-2019)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2018-`ind'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2018.csv", replace
restore



*************
* 2021-2022 *
*************

use abi `varlist' using "$data_dir/2021.dta", clear
ren * *21
ren abi21 abi

isid abi


merge 1:1 abi using "$data_dir/2022.dta"
ren * *22
ren abi22 abi
ren *2122 *21



* Establishment Exits (i.e. just that location closed)
gen est_exit = _merge == 1
gen est_entry = year1stappeared21 == 2021

gen exists2021 = inlist(_merge, 1, 3)

gen est_age = 2021 - year1stappeared21

gen naics2 = int(primarynaicscode21/1000000)
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


gen cbsaname = "New York-Newark-Jersey City, NY-NJ-PA" if cbsacode21 == 35620
	replace cbsaname = "Los Angeles-Long Beach-Anaheim, CA" if cbsacode21 == 31080
	replace cbsaname = "Chicago-Naperville-Elgin, IL-IN-WI" if cbsacode21 == 16980
	replace cbsaname = "Houston-The Woodlands-Sugar Land, TX" if cbsacode21 == 26420
	replace cbsaname = "Phoenix-Mesa-Scottsdale, AZ" if cbsacode21 == 38060
	replace cbsaname = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if cbsacode21 == 37980
	
preserve // aggregate exit rates
	collapse (sum) est_exit est_entry exists2021, fast
	gen est_exit_rate = est_exit/exists2021
	gen est_entry_rate = est_entry/exists2021
	export delimited "$proj_dir/output/est_agg_entry_exit_2021.csv", replace
restore

preserve // exit rates by firm age
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2021, by(est_age) fast
	gen est_exit_rate = est_exit/exists2021
	egen exists_tot = sum(exists2021)
		replace exists2021 = exists_tot if est_age == "Total"
		drop exists_tot
	gen est_entry_rate = est_entry/exists2021
	graph bar est_exit_rate if est_age != "Total", over(est_age)  bar(1,col(edkblue)) ///
		ti("Aggregate (2021-2022)") subti("Firm Age",pos(6)) ///
		yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2021.png", replace as(png)
	export delimited "$proj_dir/output/est_age_exit_2021.csv", replace
restore

preserve // exit rates by firm age and CBSA
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2021, by(est_age cbsaname cbsacode21) fast
	drop if cbsaname == ""
	gen est_exit_rate = est_exit/exists2021
	gen est_entry_rate = est_entry/exists2021
	foreach city in "New York" "Los Angeles" "Chicago" "Houston" "Phoenix" "Philadelphia" {
		graph bar est_exit_rate if strpos(cbsaname,"`city'") > 0, over(est_age) bar(1,col(edkblue)) ///
				ti("`city' (2021-2022)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2021-`city'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2021.csv", replace
restore



preserve // exit rates by firm age and industry (NAICS 2-digit)
	replace est_age = 6 if est_age > 6 & est_age != .
	tostring est_age, replace
	replace est_age = "6+" if est_age == "6"
	replace est_age = "Total" if inlist(est_age,".","")
	collapse (sum) est_exit est_entry exists2021, by(est_age naics2desc) fast
	drop if naics2desc == ""
	gen est_exit_rate = est_exit/exists2021
	gen est_entry_rate = est_entry/exists2021
	foreach ind of global industries {
		graph bar est_exit_rate if strpos(naics2desc,"`ind'") ==1, over(est_age) bar(1,col(edkblue)) ///
				ti("`ind' (2021-2022)") subti("Firm Age",pos(6)) ///
				yti("Exit Rate for Establishments")  ylab(0(0.05)0.35)
		graph export "$proj_dir/output/est_age_exit_2021-`ind'.png", replace as(png)
	}
	export delimited "$proj_dir/output/est_age_CBSA_exit_2021.csv", replace
restore



* Firm Exits






















