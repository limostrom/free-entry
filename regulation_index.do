/*





*/

clear all
pause on



cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/regdata/RegData-US_4-1"


* Naics names
import delimited "../../../processed-data/naics2.csv", clear varn(1)
tempfile inds
save `inds', replace

* Probabilities
import delimited "2digit_probability.csv", clear varn(1)
tempfile probs
save `probs', replace

* Sector Weights ---------------------------------------------------------------
import delimited "../../../processed-data/regs_full.csv", clear varn(1)

collapse (sum) bds_tot_hp, by(naics2 year)
bys year: egen tot_firms = total(bds_tot_hp)
gen weight = bds_tot_hp / tot_firms
drop if naics2 == ""

tempfile weights
save `weights', replace
* ------------------------------------------------------------------------------

import delimited "document_restrictions.csv", clear varn(1)

gen year = substr(date,1,4)
keep document_id year restrictions_2_0 conditionals words

joinby document_id using `probs'

gen restr = restrictions_2_0 * probability
gen conds_per_word = conditionals / words * probability
gen naics2 = string(industry)
	replace naics2 = "31-33" if inlist(naics2,"31","32","33")
	replace naics2 = "44-45" if inlist(naics2,"44","45")
	replace naics2 = "48-49" if inlist(naics2,"48","49")
collapse (sum) restr conds_per_word, by(year naics2)
merge m:1 naics2 using `inds', nogen

destring year, replace
levelsof naics2short, local(indlist)
sort naics2 year
foreach i of local indlist {
	#delimit ;
	
	tw (line restr year if naics2short == "`i'", lc(purple)),
	  legend(off) ti("Regulation Index for `i'")
	yti("Total Restrictions") xti("Year");
	
	graph export "../../../output/regidx_restrictions_ts-`i'.pdf", replace as(pdf);
	
	tw (line conds_per_word year if naics2short == "`i'", lc(purple)),
	  legend(off) ti("Regulation Index for `i'")
	  yti("Conditionals Scaled by Total Words") xti("Year");
	
	graph export "../../../output/regidx_conds_ts-`i'.pdf", replace as(pdf);
	
	#delimit cr
}

preserve
	merge 1:1 naics2 year using `weights', keep(1 3) nogen
		gen restr_wtd = restr * weight
		gen conds_wtd = conds_per_word * weight
	collapse (sum) restr_wtd conds_wtd, by(year)
	keep if inrange(year, 1979, 2019)
	#delimit ;
	tw (line restr_wtd year, lc(purple)),
	  legend(off) ti("Aggregate Regulation Index") subti("(Sectors Firm-Share Weighted)")
	yti("Total Restrictions") xti("Year");
	
	graph export "../../../output/regidx_restrictions_ts_agg.pdf", replace as(pdf);
	
	tw (line conds_wtd year, lc(purple)),
	  legend(off) ti("Aggregate Regulation Index") subti("(Sectors Firm-Share Weighted)")
	  yti("Conditionals Scaled by Total Words") xti("Year");
	
	graph export "../../../output/regidx_conds_ts_agg.pdf", replace as(pdf);
	
	#delimit cr
restore


collapse (mean) restr conds_per_word, by(naics2 naics2short)
egen cond_rank = rank(conds_per_word), track
egen restr_rank = rank(restr), track


export delimited "../../../processed-data/regulation_index.csv", replace
