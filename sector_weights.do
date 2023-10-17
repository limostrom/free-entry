



set scheme s1color


clear all
pause on

global proj_dir  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/"
cd "$proj_dir/processed-data/"


import delimited "regs_full.csv", clear varn(1)

ren bds_tot_hp T_ist
bys statefips year: egen T_st = sum(T_ist)

gen w_ist = T_ist / T_st
collapse (mean) w_i = w_ist, by(naics2)

gen beta_ols = -0.019 if naics2 == "11"
	replace beta_ols = 1.065 if naics2 == "21"
	replace beta_ols = 0.555 if naics2 == "22"
	replace beta_ols = 1.956 if naics2 == "23"
	replace beta_ols = 0.454 if naics2 == "31-33"
	replace beta_ols = 0.480 if naics2 == "42"
	replace beta_ols = 0.471 if naics2 == "44-45"
	replace beta_ols = 0.609 if naics2 == "48-49"
	replace beta_ols = 0.508 if naics2 == "51"
	replace beta_ols = 0.650 if naics2 == "52"
	replace beta_ols = 1.181 if naics2 == "53"
	replace beta_ols = 0.855 if naics2 == "54"
	replace beta_ols = 0.387 if naics2 == "55"
	replace beta_ols = 0.936 if naics2 == "56"
	replace beta_ols = 0.279 if naics2 == "61"
	replace beta_ols = 0.426 if naics2 == "62"
	replace beta_ols = 0.587 if naics2 == "71"
	replace beta_ols = 0.378 if naics2 == "72"
	replace beta_ols = 0.450 if naics2 == "81"
	replace beta_ols = 0.745 if naics2 == ""

gen w_beta = beta_ols * w_i
egen beta_ind = sum(w_beta) if naics2 != ""
