library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(mFilter)
library(readxl)
library(xtable)
library(readr)

#######################################
# Working Age Population Calculations #
#######################################
# Set working directory
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/intercensal_pop/"

# Open intercensal estimates for 1970-1979
fwf <- fwf_widths(c(2, 3, 10, rep(8,11)))
ic70 <- read_fwf(paste0(filepath, "e7080sta.txt"), fwf, skip=14)
colnames(ic70) <- c("statefips", "statename", "age",
        "1970", "1971", "1972", "1973", "1974",
        "1975", "1976", "1977", "1978", "1979", "1980")
# Reshape the ic70 data frame from wide to long format
ic70_long <- pivot_longer(ic70, cols = "1970":"1980",
        names_to = "year", values_to = "pop")
ic70_wide <- pivot_wider(ic70_long,
        names_from = "age", values_from = "pop")
wap70 <- ic70_wide %>%
        filter(!is.na(statefips) & year != "1980") %>%
        mutate(year = as.numeric(year)) %>%
        mutate(wap_state = rowSums(select(., "20":"62-64F"))) %>%
        group_by(year) %>%
        summarize(wap = sum(wap_state))

# Open intercensal estimates for 1980-1989
filenames <- list.files(path = filepath, pattern = "^E\\d{4}RQI.TXT", full.names = TRUE)
ic80 <- lapply(filenames, read_fwf, fwf_widths(c(2, 2, 2, 4, 11)))
ic80 <- do.call(rbind, ic80)
colnames(ic80) <- c("series", "month", "year", "age", "pop")
ic80 <- ic80 %>%
        mutate(year = year + 1900) %>%
        filter(month == 7 & !is.na(year)) %>%
        filter(age >= 20 & age <= 64) %>%
        select(year, age, pop)
ic80_wide <- pivot_wider(ic80,
                names_from = "age", values_from = "pop")
wap80 <- ic80_wide %>%  
        mutate(wap = rowSums(select(., "20":"64"))) %>%
        select(year, wap)

# Open intercensal estimates for 1990-1999
ic90 <- read.csv(paste0(filepath, "us-est90int-07.csv"), header = FALSE)
colnames(ic90) <- c("DATE", "AGE", "TOT_POP", "MALE", "FEMALE")
ic90 <- separate(ic90, DATE, into = c("MONTH", "YEAR"), sep = ",") %>%
        filter(MONTH == "July 1" & !is.na(YEAR)) %>%
        mutate(YEAR = as.numeric(YEAR), AGE = as.numeric(AGE)) %>%
        filter(AGE >= 20 & AGE <= 64) %>%
        rename(year = YEAR, age = AGE, pop = TOT_POP) %>%
        select(year, age, pop)
# Reshape ic90 from long to wide format
ic90_wide <- pivot_wider(ic90,
                names_from = "age", values_from = "pop")
wap90 <- ic90_wide %>%  
        mutate(wap = rowSums(select(., "20":"64"))) %>%
        select(year, wap)

filepath <- "raw-data/acs_pop/"
# Open intercensal estimates for 2004
ic00 <- read.csv(paste0(filepath, "us-est00int-alldata.csv"), header = TRUE)
# Select only the columns we need
ic00 <- ic00 %>%
        filter(MONTH == 7) %>%
        select(YEAR, AGE, TOT_POP) %>%
        filter(YEAR >= 2000 & YEAR <= 2004) %>%
        filter(AGE >= 20 & AGE <= 64) %>%
        rename(year = YEAR, age = AGE, pop = TOT_POP)
# Reshape ic from long to wide format
ic00_wide <- pivot_wider(ic00,
                names_from = "age", values_from = "pop")
wap00 <- ic00_wide %>%  
        mutate(wap = rowSums(select(., "20":"64"))) %>%
        select(year, wap)

# Append ACS data for 2005-2019
filenames <- list.files(path = filepath, pattern = "acs_natl_\\d{4}.csv", 
                         full.names = TRUE)
wap <- lapply(filenames, read.csv, header = TRUE)
wap <- do.call(rbind, wap) %>%
        select(year, wap) %>%
        filter(year != 2021)
wap <- rbind(wap70, wap80, wap90, wap00, wap) %>%
        filter(year >= 1978 & year <= 2019)

# Apply the HP filter with a smoothing parameter of 6.25
wap$wap_hp <- hpfilter(wap$wap, freq = 6.25)$trend

# Compute year-over-year changes in wap
wap <- wap %>% mutate(d_wap_hp = (wap_hp - lag(wap_hp))/lag(wap_hp)*100)

# Compute average of d_wap for 1979-81, 2005-07 and 2017-19
eta_wap_79 <- wap %>%
        filter(year >= 1979 & year <= 1981) %>%
        summarize(eta_wap_79 = mean(d_wap_hp)) %>%
        pull(eta_wap_79)
eta_wap_05 <- wap %>%
        filter(year >= 2005 & year <= 2007) %>%
        summarize(eta_wap_05 = mean(d_wap_hp)) %>%
        pull(eta_wap_05)
eta_wap_17 <- wap %>%
        filter(year >= 2017 & year <= 2019) %>%
        summarize(eta_wap_17 = mean(d_wap_hp)) %>%
        pull(eta_wap_17)

########################
# Civilian Labor Force #
########################
# Read in the BLS file
# (downloaded from FRED: https://fred.stlouisfed.org/series/CLF16OV)
filepath <- "raw-data/bls_clf/"
bls <- read.csv(paste0(filepath,"CLF16OV.csv"))
# Extract the first four characters of the DATE variable in bls = year
bls$year <- substr(bls$DATE, 1, 4)
# Convert CLF from thousands back to raw number
bls$clf <- bls$CLF16OV * 1000
# Keep only year and CLF
bls <- bls %>% select(year, clf) %>%
        mutate(year = as.numeric(year)) %>%
        filter(year >= 1978 & year <= 2019)
# Apply the HP filter with a smoothing parameter of 6.25
bls$clf_hp <- hpfilter(bls$clf, freq = 6.25)$trend
# Compute year-over-year changes in clf
bls <- bls %>% mutate(d_clf_hp = (clf_hp - lag(clf_hp))/lag(clf_hp)*100)

# Compute average of d_clf for 1979-81, 2005-07 and 2017-19
eta_clf_79 <- bls %>%
        filter(year >= 1979 & year <= 1981) %>%
        summarize(eta_clf_79 = mean(d_clf_hp)) %>%
        pull(eta_clf_79)
eta_clf_05 <- bls %>%
        filter(year >= 2005 & year <= 2007) %>%
        summarize(eta_clf_05 = mean(d_clf_hp)) %>%
        pull(eta_clf_05)
eta_clf_17 <- bls %>%
        filter(year >= 2017 & year <= 2019) %>%
        summarize(eta_clf_17 = mean(d_clf_hp)) %>%
        pull(eta_clf_17)

########################
# Startup & Exit Rates #
########################
# Read in merged BDS-DataAxle data
m <- read.csv("processed-data/bds_axle_ts.csv", header=TRUE)
m <- m %>%
  mutate(bds_exits = bds_firms_tot + lead(bds_firms_age0) - lead(bds_firms_tot)) %>%
  filter(year < 2020) %>%
  mutate(bds_exits_hp = hpfilter(bds_exits, freq = 6.25)$trend,
         bds_starts_hp = hpfilter(bds_firms_age0, freq = 6.25)$trend,
         bds_tot_hp = hpfilter(bds_firms_tot, freq = 6.25)$trend) %>%
  mutate(bds_er_hp = bds_exits_hp / bds_tot_hp * 100,
         bds_sr_hp = bds_starts_hp / bds_tot_hp * 100)
# Pull in DataAxle exit rates
filepath <- "processed-data/exit_rates/"
da_exits <- list()
da_n <- list()
da_new <- list()
for (y in 1997:2019) {
        da <- read_dta(paste0(filepath,"agg", y, "_er.dta"))
        exits <- sum(da$firm_exit)
        da_exits <- c(da_exits, exits)
        da <- read_dta(paste0("processed-data/startup_rates/agg", y, "_sr.dta"))
        starts <- as.numeric(da$new_firm)
        da_new <- c(da_new, starts)
        n <- as.numeric(da$n_firms)
        da_n <- c(da_n, n)
}
da_exits <- hpfilter(as.numeric(da_exits), freq = 6.25)$trend
da_new <- hpfilter(as.numeric(da_new), freq = 6.25)$trend
da_n <- hpfilter(as.numeric(da_n), freq = 6.25)$trend

m$axle_exits_hp <- c(rep(NA,18), da_exits)
m$axle_starts_hp <- c(rep(NA,18), da_new)
m$axle_tot_hp <- c(rep(NA,18), da_n)

m <- m %>%
  mutate(axle_er_hp = axle_exits_hp / axle_tot_hp * 100,
         axle_sr_hp = axle_starts_hp / axle_tot_hp * 100)
  
# Pull out BDS Exit Rate for 1979-1981
x_bds_79 <- m %>%
  filter(year >= 1979 & year <= 1981) %>%
  summarize(mean_bds_er = mean(bds_er_hp)) %>%
  pull()
# Pull out average Exit Rates for 2005-2007
x_bds_05 <- m %>%
  filter(year >= 2005 & year <= 2007) %>%
  summarize(mean_bds_er = mean(bds_er_hp)) %>%
  pull()
x_axle_05 <- m %>%
  filter(year >= 2005 & year <= 2007) %>%
  summarize(mean_axle_er = mean(axle_er_hp)) %>%
  pull()
  # Pull out average Exit Rates for 2017-2019
x_bds_17 <- m %>%
  filter(year >= 2017 & year <= 2019) %>%
  summarize(mean_bds_er = mean(bds_er_hp)) %>%
  pull()
x_axle_17 <- m %>%
  filter(year >= 2017 & year <= 2019) %>%
  summarize(mean_axle_er = mean(axle_er_hp)) %>%
  pull()
# Pull out BDS Startup Rate for 1979-1981
avg_sr_bds_79 <- m %>%
  filter(year >= 1979 & year <= 1981) %>%
  summarize(mean_bds_sr = mean(bds_sr_hp)) %>%
  pull()
# Pull out average Startup Rates for 2005-2007
avg_sr_bds_05 <- m %>%
  filter(year >= 2005 & year <= 2007) %>%
  summarize(mean_bds_sr = mean(bds_sr_hp)) %>%
  pull()
avg_sr_axle_05 <- m %>% 
  filter(year >= 2005 & year <= 2007) %>%
  summarize(mean_axle_sr = mean(axle_sr_hp)) %>%
  pull()
# Pull out average Startup Rates for 2017-2019
avg_sr_bds_17 <- m %>%
  filter(year >= 2017 & year <= 2019) %>%
  summarize(mean_bds_sr = mean(bds_sr_hp)) %>%
  pull()
avg_sr_axle_17 <- m %>%
  filter(year >= 2017 & year <= 2019) %>%
  summarize(mean_axle_sr = mean(axle_sr_hp)) %>%
  pull()

# Compute predicted startup rates using flow-balance formula
pred_sr_wap_bds_79 <- (eta_wap_79 / 100 + x_bds_79 / 100) /
                        (1 + eta_wap_79 / 100) * 100
pred_sr_wap_bds_05 <- (eta_wap_05 / 100 + x_bds_79 / 100) /
                        (1 + eta_wap_05 / 100) * 100
pred_sr_wap_bds_17 <- (eta_wap_17 / 100 + x_bds_05 / 100) /
                        (1 + eta_wap_17 / 100) * 100
pred_sr_wap_axle_05 <- (eta_wap_05 / 100 + x_axle_05 / 100) /
                        (1 + eta_wap_05 / 100) * 100
pred_sr_wap_axle_17 <- (eta_wap_17 / 100 + x_axle_17 / 100) /
                        (1 + eta_wap_17 / 100) * 100
pred_sr_clf_bds_79 <- (eta_clf_79 / 100 + x_bds_79 / 100) /
                        (1 + eta_clf_79 / 100) * 100
pred_sr_clf_bds_05 <- (eta_clf_05 / 100 + x_bds_79 / 100) /
                        (1 + eta_clf_05 / 100) * 100
pred_sr_clf_bds_17 <- (eta_clf_17 / 100 + x_bds_05 / 100) /
                        (1 + eta_clf_17 / 100) * 100
pred_sr_clf_axle_05 <- (eta_clf_05 / 100 + x_axle_05 / 100) /
                        (1 + eta_clf_05 / 100) * 100
pred_sr_clf_axle_17 <- (eta_clf_17 / 100 + x_axle_17 / 100) /
                        (1 + eta_clf_17 / 100) * 100

# Compute Changes 1979-81 to 2005-2007
change_eta_wap <- eta_wap_05 - eta_wap_79
change_eta_clf <- eta_clf_05 - eta_clf_79
change_x_bds <- x_bds_05 - x_bds_79
change_sr_bds <- avg_sr_bds_05 - avg_sr_bds_79
change_pred_sr_wap_bds <- pred_sr_wap_bds_05 - pred_sr_wap_bds_79
change_pred_sr_clf_bds <- pred_sr_clf_bds_05 - pred_sr_clf_bds_79

# Form table for easier export
tab1 <- data.frame(
        "Labor Supply Gr (WAP)" = c(eta_wap_79, eta_wap_05, change_eta_wap),
        "Labor Supply Gr (CLF)" = c(eta_clf_79, eta_clf_05, change_eta_clf),
        "Exit Rate (BDS)" = c(x_bds_79, x_bds_05, change_x_bds),
        "Actual SR (BDS)" = c(avg_sr_bds_79, avg_sr_bds_05, change_sr_bds),
        "Predicted SR (WAP, BDS)" = c(pred_sr_wap_bds_79, pred_sr_wap_bds_05, change_pred_sr_wap_bds),
        "Predicted SR (CLF, BDS)" = c(pred_sr_clf_bds_79, pred_sr_clf_bds_05, change_pred_sr_clf_bds)) %>%
        mutate_all(round, digits = 1)

# Use xtable to create a LaTeX table
table1 <- xtable(tab1, caption = "Flow-Balance Decomposition (BDS)")
# Export the tables to LaTeX files\
print(table1, file = "output/tables/table1.tex")

# Compute Changes 2005-2007 to 2017-2019
change_eta_wap <- eta_wap_17 - eta_wap_05
change_eta_clf <- eta_clf_17 - eta_clf_05
change_x_bds <- x_bds_17 - x_bds_05
change_x_axle <- x_axle_17 - x_axle_05
change_sr_bds <- avg_sr_bds_17 - avg_sr_bds_05
change_sr_axle <- avg_sr_axle_17 - avg_sr_axle_05
change_pred_sr_wap_bds <- pred_sr_wap_bds_17 - pred_sr_wap_bds_05
change_pred_sr_clf_bds <- pred_sr_clf_bds_17 - pred_sr_clf_bds_05
change_pred_sr_wap_axle <- pred_sr_wap_axle_17 - pred_sr_wap_axle_05
change_pred_sr_clf_axle <- pred_sr_clf_axle_17 - pred_sr_clf_axle_05

# Form table for easier export
tab2A <- data.frame(
        "Labor Supply Gr (WAP)" = c(eta_wap_05, eta_wap_17, change_eta_wap),
        "Labor Supply Gr (CLF)" = c(eta_clf_05, eta_clf_17, change_eta_clf),
        "Exit Rate (BDS)" = c(x_bds_05, x_bds_17, change_x_bds),
        "Actual SR (BDS)" = c(avg_sr_bds_05, avg_sr_bds_17, change_sr_bds),
        "Predicted SR (WAP, BDS)" = c(pred_sr_wap_bds_05, pred_sr_wap_bds_17, change_pred_sr_wap_bds),
        "Predicted SR (CLF, BDS)" = c(pred_sr_clf_bds_05, pred_sr_clf_bds_17, change_pred_sr_clf_bds)) %>%
        mutate_all(round, digits = 1)
tab2B <-data.frame(
        "Labor Supply Gr (WAP)" = c(eta_wap_05, eta_wap_17, change_eta_wap),
        "Labor Supply Gr (CLF)" = c(eta_clf_05, eta_clf_17, change_eta_clf),
        "Exit Rate (Axle)" = c(x_axle_05, x_axle_17, change_x_axle),
        "Actual SR (Axle)" = c(avg_sr_axle_05, avg_sr_axle_17, change_sr_axle),
        "Predicted SR (WAP, Axle)" = c(pred_sr_wap_axle_05, pred_sr_wap_axle_17, change_pred_sr_wap_axle),
        "Predicted SR (CLF, Axle)" = c(pred_sr_clf_axle_05, pred_sr_clf_axle_17, change_pred_sr_clf_axle)) %>%
        mutate_all(round, digits = 1)

# Use xtable to create a LaTeX table
table2A <- xtable(tab2A, caption = "Flow-Balance Decomposition (BDS)")
table2B <- xtable(tab2B, caption = "Flow-Balance Decomposition (DataAxle)")
# Export the tables to LaTeX files\
print(table2A, file = "output/tables/table2A.tex")
print(table2B, file = "output/tables/table2B.tex")
