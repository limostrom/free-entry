/*

birth_data.do

*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/"

local filelist: dir "cdc_births" files "*.csv.zip"
cd "cdc_births"

* Unizp each annual file, then save counts of babies by county to merge later w CBSA codes
foreach file of local filelist {
	unzipfile "`file'"
	local csvname = substr("`file'",1,12)
	import delimited "`csvname'", clear varn(1)
	keep stresfip cntyrfip smsarfip
	ren stresfip statefips
	ren cntyrfip countyfips
	bys statefips countyfips: gen births = _N
	duplicates drop
	
	local year = substr("`file'",5,4)
	gen L20_year = `year'
	gen merge_year = L20_year + 20
	
	save "../../processed-data/birth_counts/counts`year'.dta", replace
	
	rm "`csvname'"
}
