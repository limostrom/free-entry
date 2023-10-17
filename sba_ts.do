clear all
pause on

cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/processed-data/"




use "sba_7a_geo.dta", clear

drop if inlist(loanstatus, "EXEMPT", "CANCLD")
gen year = substr(firstdisbursementdate, -4,.)
	destring year, replace
	keep if inrange(year, 1991, 2019)
	
ren sbaguaranteedapproval amt
	replace amt = amt/1000
ren initialinterestrate r

#delimit ;
collapse (mean) r_mean = r amt_mean = amt (p25) r_p25 = r amt_p25 = amt
		 (p75) r_p75 = r amt_p75 = amt (sum) amt_sum = amt, by(year) fast;

tw (line r_p25 year, lp(_) lc(erose)) (line r_p75 year, lp(_) lc(erose))
   (line r_mean year, lp(l) lc(cranberry)),
 legend(order(3 "Mean Interest Rate" 1 "IQR") r(1)) yti("Interest Rate (%)")
 xti("Year") ti("Interest Rate on SBA-Backed Loans") xlab(1990(5)2020);
graph export "../output/figures/sba_intrate_ts.pdf", replace as(pdf);


tw (line amt_p25 year, lp(_) lc(eltgreen)) (line amt_p75 year, lp(_) lc(eltgreen))
   (line amt_mean year, lp(l) lc(dkgreen)),
 legend(order(3 "Mean Amount" 1 "IQR") r(1)) yti("Guarantee Amount ($000s)")
 xti("Year") ti("Guarantee Amounts for SBA-Backed Loans") xlab(1990(5)2020);
graph export "../output/figures/sba_amounts_ts.pdf", replace as(pdf);


replace amt_sum = amt_sum/1000000;
tw (line amt_sum year, lp(l) lc(dkgreen)),
 legend(off) yti("Total Guarantee Amount ($ Billions)")
 xti("Year") ti("Sum of Guarantee Amounts for SBA-Backed Loans") xlab(1990(5)2020);
graph export "../output/figures/sba_totguar_ts.pdf", replace as(pdf);

#delimit cr
