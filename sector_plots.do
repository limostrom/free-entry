/*
sector_plots.do



*/


clear all
pause on



cd  "/Users/laurenmostrom/Dropbox/Personal Document Backup/Booth/Second Year/"
cd "Y2 Paper/Finance & Dynamism/output/"


* First load in FD results
import delimited "tables/fd_table.csv", clear varn(1)

ren estimate fd_coeff
ren std_error fd_se
keep naics2short fd_coeff fd_se

tempfile fd
save `fd', replace


* Next load in IV results
import delimited "tables/iv_table_under5.csv", clear varn(1)


ren estimate iv_coeff
ren std_error iv_se
keep naics2short iv_coeff iv_se

tempfile iv
save `iv', replace


* Now Regulation index rankings
import delimited "../processed-data/regulation_index.csv", clear varn(1)

keep naics2short cond_rank restr_rank

replace cond_rank = cond_rank - 1 if cond_rank > 10
replace restr_rank = restr_rank - 1 if restr_rank > 10
drop if naics2short == "Public Administration"

tempfile reg
save `reg', replace

* Now Mian-Sufi Tradability Rankings
import delimited "../processed-data/miansufi_index.csv", clear varn(1)

keep naics2short ms_rank
sort ms_rank naics2short
gen ms_adj_rank = _n
	replace ms_adj_rank = . if naics2short == "Public Administration"
	
tempfile ms
save `ms', replace
pause

* Now Rajan-Zingales index rankings
import delimited "../processed-data/rajanzingales_index.csv", clear varn(1)

keep naics2short rz_rank rz_rd_rank caplease_rank
drop if inlist(naics2short, "", "Public Administration", "Management")
replace rz_rd_rank = rz_rd_rank - 1 if naics2short == "Utilities"


merge 1:1 naics2short using `reg', nogen
merge 1:1 naics2short using `ms', nogen
merge 1:1 naics2short using `fd', nogen
merge 1:1 naics2short using `iv', nogen


gen fd_ci_lb = fd_coeff - 1.96 * fd_se
gen fd_ci_ub = fd_coeff + 1.96 * fd_se
gen iv_ci_lb = iv_coeff - 1.96 * iv_se
gen iv_ci_ub = iv_coeff + 1.96 * iv_se

foreach var of varlist *rank {
	gen `var'_x_iv = `var' + 0.25
}


* ----------------------------- PLOTS ------------------------------------------

* Regulation Rank
#delimit ;
tw (rcap fd_ci_lb fd_ci_ub restr_rank, lc(eltgreen))
   (scatter fd_coeff restr_rank, mc(eltgreen) msym(O))
   (rcap iv_ci_lb iv_ci_ub restr_rank_x_iv, lc(dkgreen))
   (scatter iv_coeff restr_rank_x_iv if iv_ci_lb <= 0, mc(white) msym(O))
   (scatter iv_coeff restr_rank_x_iv if iv_ci_lb <= 0, mc(dkgreen) msym(Oh))
   (scatter iv_coeff restr_rank_x_iv if iv_ci_lb > 0, mc(dkgreen) msym(O)),
   yline(0,lc(gs12) lp(-)) ti("Sector Elasticities and Regulatory Barriers to Entry")
  legend(order(1 "95% Confidence Interval" 2 "FD Coefficient" 6 "IV Coefficient") r(1))
  yti("Elasticity Estimate") xti("Regulation Index Ranking" "(Ascending Order)");
  
graph export "figures/coeffs_bysector_regindx.pdf", replace as(pdf);

#delimit cr

* Rajan-Zingales Ranking
#delimit ;
tw (rcap fd_ci_lb fd_ci_ub rz_rank, lc(eltgreen))
   (scatter fd_coeff rz_rank, mc(eltgreen) msym(O))
   (rcap iv_ci_lb iv_ci_ub rz_rank_x_iv, lc(dkgreen))
   (scatter iv_coeff rz_rank_x_iv if iv_ci_lb <= 0, mc(white) msym(O))
   (scatter iv_coeff rz_rank_x_iv if iv_ci_lb <= 0, mc(dkgreen) msym(Oh))
   (scatter iv_coeff rz_rank_x_iv if iv_ci_lb > 0, mc(dkgreen) msym(O)),
   yline(0,lc(gs12) lp(-))  ti("Sector Elasticities and Financial Barriers to Entry")
  legend(order(1 "95% Confidence Interval" 2 "FD Coefficient" 6 "IV Coefficient") r(1))
  yti("Elasticity Estimate") xti("Rajan-Zingales Index Ranking" "(Ascending Order)");
  
graph export "figures/coeffs_bysector_rzindx.pdf", replace as(pdf);

#delimit cr

* Capital Leases Ranking
#delimit ;
tw (rcap fd_ci_lb fd_ci_ub caplease_rank, lc(eltgreen))
   (scatter fd_coeff caplease_rank, mc(eltgreen) msym(O))
   (rcap iv_ci_lb iv_ci_ub caplease_rank_x_iv, lc(dkgreen))
   (scatter iv_coeff caplease_rank_x_iv if iv_ci_lb <= 0, mc(white) msym(O))
   (scatter iv_coeff caplease_rank_x_iv if iv_ci_lb <= 0, mc(dkgreen) msym(Oh))
   (scatter iv_coeff caplease_rank_x_iv  if iv_ci_lb > 0, mc(dkgreen) msym(O)),
   yline(0,lc(gs12) lp(-))  ti("Sector Elasticities and Financial Barriers to Entry")
  legend(order(1 "95% Confidence Interval" 2 "FD Coefficient" 6 "IV Coefficient") r(1))
  yti("Elasticity Estimate") xti("Capital Leases / PP&E Ranking" "(Ascending Order)");
  
graph export "figures/coeffs_bysector_clindx.pdf", replace as(pdf);

#delimit cr


* Mian-Sufi Tradability Ranking
#delimit ;
tw (rcap fd_ci_lb fd_ci_ub ms_adj_rank, lc(eltgreen))
   (scatter fd_coeff ms_adj_rank, mc(eltgreen) msym(O))
   (rcap iv_ci_lb iv_ci_ub ms_adj_rank_x_iv, lc(dkgreen))
   (scatter iv_coeff ms_adj_rank_x_iv if iv_ci_lb <= 0, mc(white) msym(O))
   (scatter iv_coeff ms_adj_rank_x_iv if iv_ci_lb <= 0, mc(dkgreen) msym(Oh))
   (scatter iv_coeff ms_adj_rank_x_iv if iv_ci_lb > 0, mc(dkgreen) msym(O)),
   yline(0,lc(gs12) lp(-))  ti("Sector Elasticities and Tradability")
   xlab(1 9 12 15 18)
  legend(order(1 "95% Confidence Interval" 2 "FD Coefficient" 6 "IV Coefficient") r(1))
  yti("Elasticity Estimate") xti("Mian-Sufi Tradability Ranking" "(Ascending Order)");
  
graph export "figures/coeffs_bysector_msindx.pdf", replace as(pdf);

#delimit cr





