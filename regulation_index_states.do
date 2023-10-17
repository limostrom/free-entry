/*





*/

clear all
pause on



cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/raw-data/regdata/"


* Naics names
import delimited "../../processed-data/naics2.csv", clear varn(1)
tempfile inds
save `inds', replace

* State names
import delimited "../../processed-data/states.csv", clear varn(1)
tempfile st
save `st', replace

* State level regulation data for construction only
** Regulations first
local indfiles: dir "State-RegData-Definitive-Edition_Regulations/data/" files "*_industry.csv"

cd "State-RegData-Definitive-Edition_Regulations/data/"
local ii = 1
foreach file of local indfiles {
	import delimited "`file'", clear varn(1)
	gen filename = "`file'"
		split filename, p("_")
	ren filename1 statename
	replace statename = statename + " " + filename2 ///
		if inlist(statename, "new", "north", "rhode", "south", "west")
	replace statename = strproper(statename)
	replace statename = "District of Columbia" if statename == "Dc"
	if `ii' == 1 {
		local ++ii
		tempfile regind
		save `regind', replace
	}
	else {
		append using `regind'
		save `regind', replace
	}
}
drop filename*
gen naics2 = substr(string(industry),1,2)
	replace naics2 = "31-33" if inlist(naics2,"31","32","33")
	replace naics2 = "44-45" if inlist(naics2,"44","45")
	replace naics2 = "48-49" if inlist(naics2,"48","49")
	keep if naics2 == "23"
merge m:1 statename using `st', nogen keep(3) // no Arkansas
merge m:1 naics2 using `inds', nogen keep(3)

collapse (sum) probability, by(statefips state statename naics2 naics2short document_id)
isid document_id

tempfile indprobs
save `indprobs', replace

cd ../

local restfiles: dir "data" files "*_restrictions.csv"
cd "data"

local ii = 1
foreach file of local restfiles {
	import delimited "`file'", clear varn(1) bindquote(strict)
	ren jurisdiction_name statename
	keep statename restrictions document_id
	
	if `ii' == 1 {
		local ++ii
		tempfile restrs
		save `restrs', replace
	}
	else {
		append using `restrs'
		save `restrs', replace
	}
}
isid document_id
merge 1:1 document_id using `indprobs'

tempfile st_regs
save `st_regs', replace

cd ../../

** Statutes
local indfiles: dir "State-RegData-Definitive-Edition_Statutes/data/" files "*_statutes_industry.csv"

cd "State-RegData-Definitive-Edition_Statutes/data/"
local ii = 1
foreach file of local indfiles {
	dis "`file'"
	import delimited "`file'", clear varn(1)
	gen filename = "`file'"
		split filename, p("_")
	ren filename1 statename
	replace statename = statename + " " + filename2 ///
		if inlist(statename, "new", "north", "rhode", "south", "west")
	replace statename = strproper(statename)
	replace statename = "District of Columbia" if statename == "Dc"
	if `ii' == 1 {
		local ++ii
		tempfile regind
		save `regind', replace
	}
	else {
		append using `regind'
		save `regind', replace
	}
}
drop filename*
gen naics2 = substr(string(industry),1,2)
	replace naics2 = "31-33" if inlist(naics2,"31","32","33")
	replace naics2 = "44-45" if inlist(naics2,"44","45")
	replace naics2 = "48-49" if inlist(naics2,"48","49")
	keep if naics2 == "23"
merge m:1 statename using `st', nogen keep(3) // no Arkansas
merge m:1 naics2 using `inds', nogen keep(3)

collapse (sum) probability, by(statefips state statename naics2 naics2short document_id)
isid document_id

tempfile indprobs
save `indprobs', replace

cd ../

local restfiles: dir "data" files "*statutes_restrictions.csv"
cd "data"

local ii = 1
foreach file of local restfiles {
	dis "`file'"
	import delimited "`file'", clear varn(1) bindquote(strict)
	ren jurisdiction_name statename
	keep statename restrictions document_id
	
	if `ii' == 1 {
		local ++ii
		tempfile restrs
		save `restrs', replace
	}
	else {
		append using `restrs'
		save `restrs', replace
	}
}
isid document_id
merge 1:1 document_id using `indprobs', keep(3)

cd ../../

append using `st_regs'

drop if restrictions == .


gen restr = restrictions * probability
collapse (sum) restr, by(naics2 naics2short statefips state statename)

egen st_restr_rank = rank(restr), track


export delimited "../../processed-data/regulation_index_bystate_constr.csv", replace

import delimited "../../processed-data/regulation_index_bystate_constr.csv", clear varn(1)
drop if naics2short == ""
replace st_restr_rank = st_restr_rank - 10

tempfile st_rank
save `st_rank', replace

import delimited "../../processed-data/regs_full.csv", clear varn(1)
	keep if naics2 == "23"
	destring naics2, replace

merge m:1 statefips naics2 using `st_rank', nogen keep(3)

export delimited "../../processed-data/regs_state_rank.csv", replace

xtset statefips year

gen sr = bds_age0_hp / bds_tot_hp
gen sr_fd = sr - l.sr
gen wapgr_fd = dln_wap_hp - l.dln_wap_hp

export delimited "../../processed-data/regs_state_rank_fd.csv", replace
