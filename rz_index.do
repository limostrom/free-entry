/*
rz_index.do




*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"


* Naics names
import delimited "../processed-data/naics2.csv", clear varn(1)
tempfile inds
save `inds', replace

* Import Compustat download
import delimited "vs65w18ykndx61ek.csv", clear varn(1)

keep gvkey naics datadate capx xrd oancf apalch invch recch dclo ppent at lcacl lcal lcat
gen year = substr(datadate,1,4)
destring year, replace

gen naics2 = substr(string(naics),1,2)
	replace naics2 = "31-33" if inlist(naics2,"31","32","33")
	replace naics2 = "44-45" if inlist(naics2,"44","45")
	replace naics2 = "48-49" if inlist(naics2,"48","49")
	
gen rz = (capx - (oancf + invch + recch + apalch)) / capx
gen rz_plusrd = (capx + xrd - (oancf + invch + recch + apalch)) / (capx + xrd)
replace dclo = . if dclo == 0
gen caplease = dclo / ppent
gen lcacl_at = lcacl / at
gen lcal_at = lcal / at
gen ppe = ppent / at

drop if naics2 == "."
collapse (p50) rz rz_plusrd caplease lcacl_at lcal_at ppe (count) n = gvkey, by(naics2 year)

collapse (mean) rz rz_plusrd caplease lcacl_at lcal_at ppe, by(naics2)
merge 1:1 naics2 using `inds', nogen

egen rz_rank = rank(rz), track
egen rz_rd_rank = rank(rz_plusrd), track
egen caplease_rank = rank(caplease), track
egen lcacl_rank = rank(lcacl_at), track
egen lcal_rank = rank(lcal_at), track
egen ppe_rank = rank(ppe), track

export delimited "../processed-data/rajanzingales_index.csv", replace
