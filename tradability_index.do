/*




*/




clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/literature/MianSufiEconometrica_PublicReplicationFiles"


* Naics names
import delimited "../../processed-data/naics2.csv", clear varn(1)
tempfile inds
save `inds', replace


* Mian & Sufi Industry Classifications (Method #1)
use "miansufieconometrica_countyindustrylevel", clear

gen naics2 = substr(naics,1,2)
	replace naics2 = "31-33" if inlist(naics2, "31", "32", "33")
	replace naics2 = "44-45" if inlist(naics2, "44", "45")
	replace naics2 = "48-49" if inlist(naics2, "48", "49")
collapse (sum) CIemp2_2007, by(naics2 indcat)

reshape wide CIemp2_2007, i(naics2) j(indcat)

egen totemp_2007 = rowtotal(CIemp2_2007?)
gen sh_emp_nontradable = CIemp2_20072 / totemp_2007
gen sh_emp_tradable = CIemp2_20071 / totemp_2007
gen sh_emp_construction = CIemp2_20073 / totemp_2007
gen sh_emp_other = CIemp2_20070 / totemp_2007

export delimited "../../processed-data/miansufi_index_alternate.csv", replace

* Mian & Sufi Industry Classifications (Method #2)
use "miansufieconometrica_countyindustrylevel", clear

gen naics2 = substr(naics,1,2)
	replace naics2 = "31-33" if inlist(naics2, "31", "32", "33")
	replace naics2 = "44-45" if inlist(naics2, "44", "45")
	replace naics2 = "48-49" if inlist(naics2, "48", "49")

collapse (sum) CIemp2_2007, by(naics2 Ihcat2)

reshape wide CIemp2_2007, i(naics2) j(Ihcat2)
egen totemp_2007 = rowtotal(CIemp2_2007?)

gen sh_emp_tradable = CIemp2_20074 / totemp_2007
	replace sh_emp_tradable = 0 if sh_emp_tradable == .

egen ms_rank = rank(sh_emp_tradable), track

merge 1:1 naics2 using `inds', nogen

export delimited "../../processed-data/miansufi_index.csv", replace
