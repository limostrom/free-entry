# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)

# Appending all BDS files into one
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/bds"
filenames <- list.files(path = filepath, pattern = "*.csv", full.names = TRUE)
bds <- lapply(filenames, read.csv, header = TRUE)
bds <- do.call(rbind, bds)

# Rename columns
colnames(bds) <- c("rownum","cbsaname", "naics2desc", "year", "firms", "estabs", "emp", "year2","naics2","cbsacode")

# Remove rownum and year2
bds <- bds %>% select(-rownum, -year2)

#Read in Infogroup tabs from Stata
procdata <- "processed-data/startup_rates"

aggfiles <- list.files(path = procdata, pattern = "^a.*_sr.dta", full.names = TRUE)
agg <- lapply(aggfiles, read_dta)
agg <- do.call(rbind, agg)
agg$naics2 <- rep(0, nrow(agg))

cbsafiles <- list.files(path = procdata, pattern = "^c.*_sr.dta", full.names = TRUE)
cbsa <- lapply(cbsafiles, read_dta)
cbsa <- do.call(rbind, cbsa)
cbsa$naics2 <- rep(0, nrow(cbsa))

# Select rows from bds with naics2 == 0
bds_indtot <- bds %>% filter(naics2 == 0)

# Merge bds_filtered with cbsa
merged <- merge(bds_indtot, cbsa, by = c("cbsacode", "year"))
colnames(merged) <- c("cbsacode", "year", 'cbsanamex', "naics2desc", "firms_bds", 
                      "estabs_bds", "emp_bds", "naics2x", "cbsanamey", "entrants_da", 
                      "firms_da", "sr_da", "naics2y")

# Compute difference between firms in bds and da
merged$diff_firms <- merged$firms_bds - merged$firms_da

# Compute the average and interquartile range of diff_firms by year
summary_stats <- merged %>% group_by(year) %>% 
  summarize(avg_diff = mean(diff_firms), 
            q1_diff = quantile(diff_firms, 0.25), 
            q3_diff = quantile(diff_firms, 0.75))

# Plot the average and interquartile range of diff_firms by year
ggplot(summary_stats, aes(x = year, y = avg_diff)) +
  geom_line() +
  geom_ribbon(aes(ymin = q1_diff, ymax = q3_diff), alpha = 0.2) +
  labs(x = "Year", y = "Difference in Firms (BDS - DA)")
