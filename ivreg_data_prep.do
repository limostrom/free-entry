/*


ivreg_data_prep.do

Assemble the following data series by CBSA and year for 2002-2019:
	- DataAxle # new firms and total # firms to get SR = age0/total
	- BDS # new firms and total # firms to get SR = age0/total
	- Working age population from ACS (age 20-64)
	- Civilian labor force from BLS
	- # births from 1982-1988 from NCHS
	- Total population and population under age 5 from Intercensal estimates
		tables to get birthrate instrument (1982-88) and alternative
		instrument (1982-1999)
*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"


* %%%%%%%%%%%%%%%%%%%%%%%%%% RHS VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* WAP --------------------------------------------------------------------------
cd "acs_pop"

* Start with 2002-2004 from intercensal estimates
import delimited "co-est00int-agesex-5yr.csv", clear varn(1) case(lower) // for 2002-04

tostring state county, replace
	replace county = "00" + county if strlen(county) == 1
	replace county = "0" + county if strlen(county) == 2
	assert strlen(county) == 3
	gen fipscd = state + county
	destring fipscd, replace

keep if sex == 0 //total
	
keep fipscd agegrp popestimate2002 popestimate2003 popestimate2004
keep if inrange(agegrp,5,13)
collapse (sum) pop*, by(fipscd)
reshape long popestimate, i(fipscd) j(year)
ren popestimate wap

merge m:1 fipscd using "../../processed-data/county_cbsa_xwalk.dta", keep(1 3)

gen nonmetro = _merge == 1
	replace cbsacode = int(fipscd/1000) if nonmetro
	drop if nonmetro // currently don't have these numbers for 2005-2019
	
collapse (sum) wap, by(cbsacode year nonmetro)

tempfile wap2004
save `wap2004', replace

* Next add 2005-2019 from ACS
forval y = 2005/2019 {
	import delimited "acs_`y'.csv", clear varn(1) case(lower)
	
	keep geoid wap
		ren geoid cbsacode
	gen year = `y'
	gen nonmetro = 0
	
	tempfile wap`y'
	save `wap`y'', replace
}

use `wap2004', clear
forval y = 2005/2019 {
	append using `wap`y''
}

tempfile wap
save `wap', replace

cd ../

* CLF --------------------------------------------------------------------------
import excel "bls_clf_sa.xlsx", clear cellra(A3:J158800) first case(lower)
drop if _n == 1

ren areafips cbsacode
ren civ clf
	drop if clf == "(n)"
keep cbsacode year month clf
destring *, replace

collapse (mean) clf, by(cbsacode year)

merge 1:1 cbsacode year using `wap', gen(_wap_clf_merge)

save "../processed-data/rhs.dta", replace

* %%%%%%%%%%%%%%%%%%%%%%%%%% LHS VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd "../processed-data"

* DataAxle ---------------------------------------------------------------------
use "startup_rates/ind-cbsa2002.dta", clear

forval y = 2003/2019 {
	append using "startup_rates/ind-cbsa`y'.dta"
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

ren new_firm axle_age0
ren n_firms axle_tot
gen axle_sr = axle_age0 / axle_tot
	drop sr
	
drop if cbsacode == .
	
tempfile axle
save `axle', replace
	
* BDS --------------------------------------------------------------------------
cd "../raw-data/"

forval y = 1997/2019 {
	local filelist: dir "bds" files "bds_`y'_*.csv"
	cd bds
	
	local ii = 1
	foreach f of local filelist {
		if strpos("`f'","_age0") > 0 | substr("`f'",10,2) == "00" {
			rm "`f'"
		}
		if strpos("`f'","_age0") == 0 & substr("`f'",10,2) != "00" {
			import delimited "`f'", clear
			drop v1
			ren v2 cbsaname
			ren v3 naicslabel
			ren v4 year
			ren v5 fage
			ren v6 firms
			ren v7 estabs
			ren v8 emp
			drop v9 // year again
			ren v10 naics2
				tostring naics2, replace
			ren v11 cbsacode
			
			keep cbsacode year naics2 fage firms
			order cbsacode year naics2 fage firms
			
			keep if inlist(fage,1,10)
			reshape wide firms, i(cbsacode year naics2) j(fage)
				ren firms1 bds_tot
				ren firms10 bds_age0
				
			gen bds_sr = bds_age0 / bds_tot
			
			if `ii' == 1 {
				tempfile bds`y'
				save `bds`y'', replace
				local ++ii
			}
			else {
				append using `bds`y''
				save `bds`y'', replace
			}
			
		}
	}
	
	cd ../
}

use `bds1997', clear
forval y = 1998/2019 {
	append using `bds`y''
}


merge 1:1 cbsacode year naics2 using `axle', gen(_bds_axle_merge)

save "../processed-data/lhs.dta", replace



* %%%%%%%%%%%%%%%%%%%%%% COMBINE W/ INSTRUMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd "../processed-data"

use "lhs.dta", clear

merge m:1 cbsacode year using "rhs.dta", nogen keep(1 3)

ren year merge_year
merge m:1 cbsacode merge_year using "birth_counts/birth_instrument_ts.dta", nogen
ren merge_year year

egen indXcbsa = group(naics2 cbsacode)
isid indXcbsa year

save "fulldata.dta", replace


