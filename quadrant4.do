/*
quadrant4.do



*/

clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"

* Quadrant 4 States
import delimited "quad4_states.csv", clear varn(1)
tempfile q4
save `q4', replace

* Exit Rates
import delimited "regs_full.csv", clear varn(1)

collapse (sum) bds_tot_hp bds_age0_hp, by(statefips year)
xtset statefips year

gen bds_exits_hp = bds_tot_hp - f.bds_tot_hp + f.bds_age0_hp
gen state_er = bds_exits_hp / bds_tot_hp

merge m:1 statefips using `q4', nogen

#delimit ;
collapse (sum) bds_exits_hp bds_tot_hp (p50) state_er_med = state_er
		 (p25) state_er_p25 = state_er (p75) state_er_p75 = state_er, by(quadrant4 year);

gen er = bds_exits_hp / bds_tot_hp * 100;
keep if inrange(year, 1979, 2018);

tw (line er year if quadrant4 == 0, lc(edkblue) lp(l))
   (line er year if quadrant4 == 1, lc(cranberry) lp(l)),
   legend(order(2 "States in Quadrant IV" 1 "All Other States"))
   ti("Exit Rates Over Time") xlab(1979(5)2019)
   yti("Exit Rate (%)") xti("Year");
graph export "../output/figures/quadrant4_ers.pdf", replace as(pdf);
#delimit cr
