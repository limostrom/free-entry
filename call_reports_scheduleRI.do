/*


call_reports.do
Instructions:
https://www.ffiec.gov/pdf/FFIEC_forms/FFIEC031_FFIEC041_202303_i.pdf
Bulk Download:
https://cdr.ffiec.gov/public/PWS/DownloadBulkData.aspx

Overdraft amounts recorded in Schedule RCC Part I 
	"ALL OTHR LN (EXCLUDE CONSUMER LN)"

Overdraft/NSF fee revenue included in Schedule RI item 5.b (RIAD4080)
	"SERVICE CHARGES ON DEP ACCTS-DOM OFF"
*/

pause on

global cr_dir "/Volumes/Seagate Por/Call Reports"
cd "$cr_dir"
cap mkdir sched_RI


* Unzip call report files and save Schedule RI only 
forval y = 2001/2022 {
	foreach m in "0331" "0630" "0930" "1231" {
		dis "Date: `m'`y'"
		unzipfile "FFIEC CDR Call Bulk All Schedules `m'`y'.zip"
		cd ../
		local schedules: dir "Call Reports" files "*.txt"
		cd "Call Reports"
		foreach subfile of local schedules {
			dis "`subfile'"
			if "`subfile'" != "FFIEC CDR Call Schedule RI `m'`y'.txt" {
				rm "`subfile'"
			}
			if "`subfile'" == "FFIEC CDR Call Schedule RI `m'`y'.txt" {
				copy "`subfile'" "sched_RI/`subfile'", replace
				rm "`subfile'"
			}
		}
	} // quarter
} // year
