/*
construction.do




*/


clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

* Read in real wages
import delimited "fred_construction_realwages.csv", clear varn(1)

gen year = substr(date, 1, 4)
	destring year, replace
ren ces2000000008 con_wages
keep year con_wages cpiaucsl
gen cpi1982 = cpiaucsl if year == 1982
	ereplace cpi1982 = max(cpi1982)

tempfile wages
save `wages', replace

* First read in all BDS data for construction
local filelist: dir "bds" files "bds_????_23.csv"
cd "bds"
local ii = 1
foreach file of local filelist {
	import delimited "`file'", clear
	
	if `ii' == 1 {
		tempfile constr
		save `constr', replace
		local ++ii
	}
	else {
		append using `constr'
		save `constr', replace
	}
}
cd ../

rename (v1-v11) (rownum statename naics2short year firmage firms estabs emp ///
		year2 naics2 statefips)

keep if inlist(firmage, 1, 10)

keep year statefips naics2 firmage firms estabs emp
reshape wide firms estabs emp, i(year statefips) j(firmage)

ren *1 *_tot
ren *10 *_age0

collapse (sum) firms_age0 firms_tot emp_age0 emp_tot, by(naics2 year)

merge 1:1 year using `wages', nogen keep(3)
tsset year

gen sr = firms_age0 / firms_tot * 100
gen d_sr = sr - l.sr
gen realwage = con_wages * cpi1982 / cpiaucsl
gen dln_emp = (ln(emp_tot) - ln(l.emp_tot)) * 100

#delimit ;
tw (line dln_emp year, lc(eltgreen) lp(l))
   (line realwage year, lc(maroon) lp(_))
   (line d_sr year, lc(edkblue) lp(l)),
  legend(order(2 "Real Hourly Wage (1982 USD)" 1 "% Change in Employment" 
				3 "Change in Startup Rate (%pts)") r(2))
  yti("") xti("Year") xlab(1979(5)2019)
  ti("Labor Market Dynamics in Construction") yline(0, lp(-) lc(gs12));
#delimit cr

graph export "../output/figures/construction_labormkt.pdf", replace as(pdf)
