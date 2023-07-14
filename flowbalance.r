library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(mFilter)
library(readxl)
library(xtable)

#######################################
# Working Age Population Calculations #
#######################################
# Set working directory
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/acs_pop/"

# Open intercensal estimates for 2004
ic <- read.csv(paste0(filepath, "us-est00int-alldata.csv"), header = TRUE)
# Select only the columns we need
ic <- ic %>% select(YEAR, AGE, TOT_POP) %>%
        filter(YEAR == 2004) %>%
        filter(AGE >= 20 & AGE <= 64) %>%
        rename(year = YEAR, age = AGE, pop = TOT_POP)
# Reshape ic from long to wide format
ic_wide <- pivot_wider(ic,
                names_from = "age", values_from = "pop")
wap04 <- ic_wide %>%  
        mutate(wap = rowSums(select(., "20":"64"))) %>%
        select(year, wap)

# Append ACS data for 2005-2019
filenames <- list.files(path = filepath, pattern = "acs_natl_\\d{4}.csv", 
                         full.names = TRUE)
wap <- lapply(filenames, read.csv, header = TRUE)
wap <- do.call(rbind, wap) %>%
        select(year, wap) %>%
        filter(year != 2021)
wap <- rbind(wap04, wap)

# Apply the HP filter with a smoothing parameter of 6.25
wap$wap_hp <- hpfilter(wap$wap, freq = 6.25)$trend

# Compute year-over-year changes in wap
wap <- wap %>% mutate(d_wap_hp = (wap_hp - lag(wap_hp))/lag(wap_hp)*100)

# Compute average of d_wap for 2005-2007 and 2017-2019
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
filepath <- "raw-data/bls_clf/"
bls <- read.csv(paste0(filepath,"CLF16OV.csv"))
# Extract the first four characters of the DATE variable in bls and store the result in a new variable called year
bls$year <- substr(bls$DATE, 1, 4)
# Convert CLF from thousands back to raw number
bls$clf <- bls$CLF16OV * 1000
# Keep only year and CLF
bls <- bls %>% select(year, clf) %>%
        filter(year < 2020)
# Apply the HP filter with a smoothing parameter of 6.25
bls$clf_hp <- hpfilter(bls$clf, freq = 6.25)$trend
# Compute year-over-year changes in clf
bls <- bls %>% mutate(d_clf_hp = (clf_hp - lag(clf_hp))/lag(clf_hp)*100)

# Compute average of d_clf for 2005-2007 and 2017-2019
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
        mutate(bds_er = bds_exits / bds_firms_tot * 100)
# Pull in DataAxle exit rates
filepath <- "processed-data/exit_rates/"
da_exits <- list()
for (y in 1997:2020) {
        da <- read_dta(paste0(filepath,"agg", y, "_er.dta"))
        exits <- sum(da$firm_exit)
        da_exits <- c(da_exits, exits)
}
m$axle_exits <- da_exits
m <- m %>%
  mutate(axle_exits = da_exits,
        axle_exits = as.numeric(axle_exits),
        axle_er = axle_exits / axle_firms_tot * 100) %>%
  filter(year < 2020)
# Apply the HP filter with a smoothing parameter of 6.25
m <- m %>%
  mutate(bds_er_hp = hpfilter(bds_er, freq = 6.25)$trend,
         axle_er_hp = hpfilter(axle_er, freq = 6.25)$trend,
         bds_sr_hp = hpfilter(bds_sr, freq = 6.25)$trend,
         axle_sr_hp = hpfilter(axle_sr, freq = 6.25)$trend)
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
pred_sr_wap_bds_05 <- (eta_wap_05 / 100 + x_bds_05 / 100) /
                        (1 + eta_wap_05 / 100) * 100
pred_sr_wap_bds_17 <- (eta_wap_17 / 100 + x_bds_05 / 100) /
                        (1 + eta_wap_17 / 100) * 100
pred_sr_wap_axle_05 <- (eta_wap_05 / 100 + x_axle_05 / 100) /
                        (1 + eta_wap_05 / 100) * 100
pred_sr_wap_axle_17 <- (eta_wap_17 / 100 + x_axle_17 / 100) /
                        (1 + eta_wap_17 / 100) * 100
pred_sr_clf_bds_05 <- (eta_clf_05 / 100 + x_bds_05 / 100) /
                        (1 + eta_clf_05 / 100) * 100
pred_sr_clf_bds_17 <- (eta_clf_17 / 100 + x_bds_05 / 100) /
                        (1 + eta_clf_17 / 100) * 100
pred_sr_clf_axle_05 <- (eta_clf_05 / 100 + x_axle_05 / 100) /
                        (1 + eta_clf_05 / 100) * 100
pred_sr_clf_axle_17 <- (eta_clf_17 / 100 + x_axle_17 / 100) /
                        (1 + eta_clf_17 / 100) * 100

# Compute Changes 2005-2007 to 2017-2019
change_eta_wap <- eta_wap_17 - eta_wap_05
change_eta_clf <- eta_clf_17 - eta_clf_05
change_x_bds <- x_bds_17 - x_bds_05
change_x_axle <- x_axle_17 - x_axle_05
change_sr_bds <- pred_sr_wap_bds_17 - pred_sr_wap_bds_05
change_sr_axle <- pred_sr_wap_axle_17 - pred_sr_wap_axle_05
change_pred_sr_wap_bds <- pred_sr_wap_bds_17 - pred_sr_wap_bds_05
change_pred_sr_clf_bds <- pred_sr_clf_bds_17 - pred_sr_clf_bds_05
change_pred_sr_wap_axle <- pred_sr_wap_axle_17 - pred_sr_wap_axle_05
change_pred_sr_clf_axle <- pred_sr_clf_axle_17 - pred_sr_clf_axle_05

# Form table for easier export
tab1A <- data.frame(
        "Labor Supply Gr (WAP)" = c(eta_wap_05, eta_wap_17, change_eta_wap),
        "Labor Supply Gr (CLF)" = c(eta_clf_05, eta_clf_17, change_eta_clf),
        "Exit Rate (BDS)" = c(x_bds_05, x_bds_17, change_x_bds),
        "Actual SR (BDS)" = c(avg_sr_bds_05, avg_sr_bds_17, change_sr_bds),
        "Predicted SR (WAP, BDS)" = c(pred_sr_wap_bds_05, pred_sr_wap_bds_17, change_pred_sr_wap_bds),
        "Predicted SR (CLF, BDS)" = c(pred_sr_clf_bds_05, pred_sr_clf_bds_17, change_pred_sr_clf_bds)) %>%
        mutate_all(round, digits = 1)
tab1B <-data.frame(
        "Labor Supply Gr (WAP)" = c(eta_wap_05, eta_wap_17, change_eta_wap),
        "Labor Supply Gr (CLF)" = c(eta_clf_05, eta_clf_17, change_eta_clf),
        "Exit Rate (Axle)" = c(x_axle_05, x_axle_17, change_x_axle),
        "Actual SR (Axle)" = c(avg_sr_axle_05, avg_sr_axle_17, change_sr_axle),
        "Predicted SR (WAP, Axle)" = c(pred_sr_wap_axle_05, pred_sr_wap_axle_17, change_pred_sr_wap_axle),
        "Predicted SR (CLF, Axle)" = c(pred_sr_clf_axle_05, pred_sr_clf_axle_17, change_pred_sr_clf_axle)) %>%
        mutate_all(round, digits = 1)

# Use xtable to create a LaTeX table
table1A <- xtable(tab1A, caption = "Table 1. Flow-Balance Decomposition (BDS)")
table1B <- xtable(tab1B, caption = "Table 1. Flow-Balance Decomposition (DataAxle)")
# Export the tables to LaTeX files
fileA <- "output/tables/table1A.tex"
print(table1A, file = fileA)
fileB <- "output/tables/table1B.tex"
print(table1B, file = fileB)