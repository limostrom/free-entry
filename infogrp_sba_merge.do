/*
Lauren Mostrom
2nd Year Paper: Finance and Dynamism

infogrp_sba_merge.do
*/



global data_dir "/Volumes/Seagate Por/infogroup in Dropbox DevBanks/_original_data/"
global proj_dir "/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism"

use "$proj_dir/processed-data/sba_504.dta", clear
gen firstdisbyr = substr(firstdisbursementdate,-4,.)
destring firstdisbyr, replace

drop if loanstatus == "CANCLD"

tostring program, replace

tempfile sba504
save `sba504', replace



use "$proj_dir/processed-data/sba_7a.dta", clear

gen firstdisbyr = substr(firstdisbursementdate,-4,.)
destring firstdisbyr, replace

drop if loanstatus == "CANCLD"

append using `sba504'

tab firstdisbyr

