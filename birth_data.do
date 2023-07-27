/*

birth_data.do

*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/cdc_births"


* Unizp each annual file, then save counts of babies by county to merge later w CBSA codes
forval y = 1968/1981 {
	unzipfile "natl`y'.csv.zip"
	import delimited "natl`y'.csv", clear varn(1)
	if `y' >= 1982 {
		keep stresfip cntyrfip
		ren stresfip statefips
		ren cntyrfip countyfips
	}
	if `y' < 1982 {
		keep stateres cntyres
		ren stateres statefips
		ren cntyres countyfips
	}
	tostring countyfips, replace
	replace countyfips = subinstr(countyfips, "Z", "",.)
	destring countyfips, replace
	bys statefips countyfips: gen births = _N
	duplicates drop
	
	gen L20_year = `y'
	gen merge_year = L20_year + 20
	
	save "../../processed-data/birth_counts/counts`y'.dta", replace
	
	rm "natl`y'.csv"
}
