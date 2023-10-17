



clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

import delimited "regs_full.csv", clear varn(1)


keep year statefips bds_sr_hp dln_wap_hp naics2
drop if naics2 == ""
replace naics2 = subinstr(naics2,"-","",.)
reshape wide bds_sr_hp, i(year statefips) j(naics2) string

xtset statefips year 

foreach var of varlist bds_sr_hp* {
	local newvarname = "d_sr_" + substr("`var'", 10, .)
	gen `newvarname' = `var' - l.`var'
}



corr d_sr_21 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_22 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23

corr d_sr_3133 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_42 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_4445 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_4849 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_61 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_62 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
corr d_sr_72 d_sr_23 l.d_sr_23 l2.d_sr_23 l3.d_sr_23 l4.d_sr_23 l5.d_sr_23
