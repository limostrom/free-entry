/*
regs_by_drs.do



*/


clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

* First map NAICS2 to SIC1 and SIC2
import excel "2022-NAICS-to-SIC-Crosswalk.xlsx", clear first

gen naics2 = int(NAICSCode/10000)

drop if RelatedSICCode == "Aux"
gen sic1 = "0" if strlen(RelatedSICCode) == 3
	replace sic1 = substr(RelatedSICCode,1,1) if strlen(RelatedSICCode) == 4
	replace sic1 = "2-3" if inlist(sic1,"2","3")
	replace sic1 = "7-8" if inlist(sic1,"7","8")

gen sic2 = substr(RelatedSICCode,1,2) if strlen(RelatedSICCode) == 4
	replace sic2 = substr(RelatedSICCode,1,3) ///
			if strlen(RelatedSICCode) == 4 & substr(RelatedSICCode,1,2) == "37"
			
bys naics2: egen mode_sic1 = mode(sic1), maxmode
drop if mode_sic1 == "9"
keep naics2 mode_sic1
duplicates drop

tostring naics2, replace
replace naics2 = "31-33" if inlist(naics2,"31","32","33")
replace naics2 = "44-45" if inlist(naics2,"44","45")
replace naics2 = "48-49" if inlist(naics2,"48","49")

duplicates drop

tempfile xwalk
save `xwalk', replace


* Now load in data for the regressions
import delimited "../processed-data/regs_full.csv", clear varn(1)
merge m:1 naics2 using `xwalk', nogen keep(3)

collapse (sum) bds_age0_hp bds_tot_hp (first) dln_wap_hp l20_birthrate l20_sh_under5_hp, ///
	by(mode_sic1 statefips year)

gen bds_sr_hp = bds_age0_hp / bds_tot_hp
	
export delimited "../processed-data/regs_full_sic1.csv", replace


egen stateXsector = group(statefips mode_sic1)
xtset stateXsector year
		
gen sr = bds_age0_hp / bds_tot_hp
gen sr_fd = sr - l.sr
gen wapgr_fd = dln_wap_hp - l.dln_wap_hp

export delimited "../processed-data/regs_full_sic1_fd.csv", replace




