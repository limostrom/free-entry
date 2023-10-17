/*




*/




cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

* Regressions by IRS vs CRS
import delimited "regs_full_sic1.csv", clear varn(1)

drop if mode_sic1 == "0"

gen irs = inlist(mode_sic1,"4","5","6")


collapse (sum) bds_age0_hp bds_tot_hp (first) dln_wap_hp l20_sh_under5_hp, ///
	by(statefips year irs)
	
gen bds_sr_hp = bds_age0_hp / bds_tot_hp

export delimited "regs_sic1_byIRS.csv", replace

* For Regressions by Tercile of Rajan-Zingales Index
import delimited "rajanzingales_index.csv", clear varn(1)
drop if inlist(naics2short,"","Management","Public Administration")
keep naics2 rz rz_rank
tempfile rz
save `rz', replace

import delimited "regs_full.csv", clear varn(1) 
merge m:1 naics2 using `rz', nogen

gen rz_low = inrange(rz_rank,1,6)
gen rz_high = inrange(rz_rank,13,18)



collapse (sum) bds_age0_hp bds_tot_hp (first) dln_wap_hp l20_sh_under5_hp, ///
	by(statefips year rz_low rz_high)
	
gen bds_sr_hp = bds_age0_hp / bds_tot_hp

export delimited "regs_naics2_byRZI.csv", replace


* For Regressions by Tercile of Regulation Index
import delimited "regulation_index.csv", clear varn(1)
replace restr_rank = restr_rank - 1 if restr_rank > 2
replace restr_rank = restr_rank - 1 if restr_rank > 9
drop if inlist(naics2short,"Management","Public Administration")
keep naics2 restr_rank
tempfile reg
save `reg', replace

import delimited "regs_full.csv", clear varn(1) 
merge m:1 naics2 using `reg', nogen

gen reg_low = inrange(restr_rank,1,6)
gen reg_high = inrange(restr_rank,13,18)



collapse (sum) bds_age0_hp bds_tot_hp (first) dln_wap_hp l20_sh_under5_hp, ///
	by(statefips year reg_low reg_high)
	
gen bds_sr_hp = bds_age0_hp / bds_tot_hp

export delimited "regs_naics2_byRegI.csv", replace
