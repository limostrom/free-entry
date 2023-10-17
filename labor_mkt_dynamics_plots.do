/*


labor_mkt_dynamics_plots.do


*/





clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"


* --- Wage Data & CPI --- *

* Read in wages
import delimited "fred_wages_nonsupervisory.csv", clear varn(1)


gen year = substr(date, 1, 4)
	destring year, replace
	
* name variables
ren ces3000000008 wages_man // Manufacturing
ren ces4200000008 wages_ret // Retail Trade
ren ces2000000008 wages_con // Construction
ren ces7000000008 wages_hos // Leisure & Hospitality
ren ces4300000008 wages_tra // Transportation & Warehousing
ren ces4142000008 wages_who // Wholesale Trade
ren ces1000000008 wages_min // Mining & Logging
ren ces4422000008 wages_uti // Utilities

gen cpi1982 = cpiaucsl if year == 1982
	ereplace cpi1982 = max(cpi1982)
	
tempfile wages
save `wages', replace


* --- Startup Rate Data --- *

	local ii = 1
foreach n in "21" "22" "23" "31-33" "42" "44-45" "48-49" "72" {
	
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

ren *1 *_tot
ren *10 *_age0

collapse (sum) firms_age0 firms_tot emp_age0 emp_tot, by(naics2 year)

gen naics2_suffix = "_min" if naics2 == "21"
	replace naics2_suffix = "_uti" if naics2 == "22"
	replace naics2_suffix = "_con" if naics2 == "23"
	replace naics2_suffix = "_man" if naics2 == "31-33"
	replace naics2_suffix = "_who" if naics2 == "42"
	replace naics2_suffix = "_ret" if naics2 == "44-45"
	replace naics2_suffix = "_tra" if naics2 == "48-49"
	replace naics2_suffix = "_hos" if naics2 == "72"
levelsof naics2_suffix, local(inds)
	
drop naics2
reshape wide firms_age0 firms_tot emp_age0 emp_tot, i(year) j(naics2_suffix) string


merge 1:1 year using `wages', nogen keep(3)
tsset year

foreach s of local inds {
	gen sr`s' = firms_age0`s' / firms_tot`s' * 100
	gen d_sr`s' = sr`s' - l.sr`s'
	gen realw`s' = wages`s' * cpi1982 / cpiaucsl
	gen dln_emp`s' = (ln(emp_tot`s') - ln(l.emp_tot`s')) * 100
}

keep if inrange(year, 1979, 2019)
* Loop through industries
foreach s of local inds {
	if "`s'" == "_min" {
		local stitle = "Mining"
	}
	if "`s'" == "_uti" {
		local stitle = "Utilities"
	}
	if "`s'" == "_con" {
		local stitle = "Construction"
	}
	if "`s'" == "_man" {
		local stitle = "Manufacturing"
	}
	if "`s'" == "_who" {
		local stitle = "Wholesale Trade"
	}
	if "`s'" == "_ret" {
		local stitle = "Retail Trade"
	}
	if "`s'" == "_tra" {
		local stitle = "Transportation & Warehousing"
	}
	if "`s'" == "_hos" {
		local stitle = "Leisure & Hospitality / Accommodation & Food"
	}
	
		
	#delimit ;
	tw (line dln_emp`s' year, lc(eltgreen) lp(l))
	   (line realw`s' year, lc(maroon) lp(_))
	   (line d_sr`s' year, lc(edkblue) lp(l)),
	  legend(order(2 "Real Hourly Wage (1982 USD)" 1 "% Change in Employment" 
					3 "Change in Startup Rate (%pts)") r(2))
	  yti("") xti("Year") xlab(1979(5)2019)
	  ti("Labor Market Dynamics") subti("`stitle'") yline(0, lp(-) lc(gs12));
	#delimit cr

	graph export "../output/figures/labormkt`s'.pdf", replace as(pdf)
	
}
