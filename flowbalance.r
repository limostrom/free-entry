library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(mFilter)
library(readxl)

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
avg_gWAP_05 <- wap %>%
            filter(year >= 2005 & year <= 2007) %>%
            summarize(avg_gWAP_05 = mean(d_wap_hp)) %>%
            pull(avg_gWAP_05)
avg_gWAP_17 <- wap %>%
            filter(year >= 2017 & year <= 2019) %>%
            summarize(avg_gWAP_17 = mean(d_wap_hp)) %>%
            pull(avg_gWAP_17)

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
avg_gCLF_05 <- bls %>%
            filter(year >= 2005 & year <= 2007) %>%
            summarize(avg_gCLF_05 = mean(d_clf_hp)) %>%
            pull(avg_gCLF_05)
avg_gCLF_17 <- bls %>%
                filter(year >= 2017 & year <= 2019) %>%
                summarize(avg_gCLF_17 = mean(d_clf_hp)) %>%
                pull(avg_gCLF_17)