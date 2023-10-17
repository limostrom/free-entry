library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(plm)
library(broom)
library(AER)
library(mFilter)

# Read in CSV from BDS
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"
ts <- read.csv(file.path(filepath, "workers_per_firm_bynaics2.csv"), header = TRUE)

# HP filter all variables
ts <- ts %>%
    filter(naics2 != "92") %>%
    group_by(naics2) %>%
    mutate(firms_tot_hp = hpfilter(firms_tot, 6.25)$trend,
        firms_age0_hp = hpfilter(firms_age0, 6.25)$trend,
        firms_inc_hp = hpfilter(firms_inc, 6.25)$trend,
        emp_tot_hp = hpfilter(emp_tot, 6.25)$trend,
        emp_age0_hp = hpfilter(emp_age0, 6.25)$trend,
        emp_inc_hp = hpfilter(emp_inc, 6.25)$trend) %>%
    mutate(avg_wrks_perfirm_inc_hp = emp_inc_hp / firms_inc_hp,
        avg_wrks_perfirm_age0_hp = emp_age0_hp / firms_age0_hp) %>%
    ungroup()

setwd("processed-data")
write.csv(ts, "workers_per_firm_bynaics2_hp.csv")