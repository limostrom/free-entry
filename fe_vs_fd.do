

set scheme s1color


clear all
pause on

global proj_dir  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/"
cd "$proj_dir/processed-data/"


import delimited "regs_full.csv", clear varn(1)
collapse (sum) bds_age0_hp bds_tot_hp (first) dln_wap_hp l20_sh_under5_hp, by(statefips year)
xtset statefips year

gen bds_sr_hp = bds_age0_hp / bds_tot_hp


gen sr_fd = bds_sr_hp - l.bds_sr_hp
gen wapgr_fd = dln_wap_hp - l.dln_wap_hp


export delimited "regs_full_fd.csv", replace

reghdfe sr_fd wapgr_fd l2.dln_wap_hp, a(statefips year) vce(robust)


* Residuals Plot
keep if inrange(year, 1979, 2007)
reghdfe bds_sr_hp dln_wap_hp, a(statefips year) vce(robust) resid
predict epsilon_it, residuals

#delimit ;
tw (scatter epsilon_it year if statefips == 17, mc(dkgreen) msym(Th)),
  legend(off) xti("Year") xlab(1979(5)2009)
  ti("TWFE Residuals Follow Random Walk") subti("(Illinois)") yti("Residual");
#delimit cr

graph export "../output/figures/residuals_twfe-IL.pdf", replace as(pdf)

corr epsilon_it l.epsilon_it

#delimit ;
tw (scatter epsilon_it year if statefips == 6, mc(dkgreen) msym(X)),
  legend(off) xti("Year") xlab(1979(5)2009)
  ti("TWFE Residuals Follow Random Walk") subti("(California)") yti("Residual");
#delimit cr

graph export "../output/figures/residuals_twfe-CA.pdf", replace as(pdf)

#delimit ;
	tw (scatter epsilon_it year if statefips == 1, mc(dkgreen) msym(x)),
	  legend(off) xti("Year") xlab(1979(5)2009)
	  ti("TWFE Residuals Follow Random Walk") yti("Residual");
	#delimit cr
