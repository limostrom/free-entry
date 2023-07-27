# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)
library(tidyr)

# Appending BDS files for national totals
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/bds"
filenames <- list.files(path = filepath, pattern = "^bds_tot_\\d{4}.csv", full.names = TRUE)
bds <- lapply(filenames, read.csv, header = TRUE)
bds <- do.call(rbind, bds)

# Rename columns
colnames(bds) <- c("rownum","country", "naics2desc", "year", "firmage", "firms", "estabs", "emp", "year2", "ones")

# Remove rownum and year2
bds <- bds %>% select(year, firmage, firms, estabs)
# Keep only firmage == 1 (total) and firmage == 10 (age 0)
bds <- bds %>% filter(firmage %in% c(1, 10))
# Reshape the data
bds_wide <- bds %>%
  pivot_wider(names_from = firmage, values_from = c("firms", "estabs"))

#Read in Infogroup tabs from Stata
procdata <- "processed-data/startup_rates"

axlefiles <- list.files(path = procdata, pattern = "^a.*_sr.dta", full.names = TRUE)
axle <- lapply(axlefiles, read_dta)
axle <- do.call(rbind, axle)

# Merge bds with dataaxle
merged <- merge(bds_wide, axle, by = "year", all.x = TRUE)
colnames(merged) <- c("year", "bds_firms_tot", "bds_firms_age0", 
            "bds_estabs_tot", "bds_estabs_age0", "axle_firms_age0",
            "axle_firms_tot", "axle_sr")
merged$bds_firms_mns <- merged$bds_firms_tot/1000000
merged$bds_firms_age0_ths <- merged$bds_firms_age0/1000
merged$axle_firms_mns <- merged$axle_firms_tot/1000000
merged$axle_firms_age0_ths <- merged$axle_firms_age0/1000
# Compute startup rate for BDS
merged$bds_sr <- merged$bds_firms_age0/merged$bds_firms_tot * 100
merged$axle_sr <- merged$axle_sr * 100

# Export the merged data
write.csv(merged, "processed-data/bds_axle_ts.csv", row.names = FALSE)