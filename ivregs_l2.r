library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(plm)
library(broom)
library(AER)
library(mFilter)
library(fixest)

##########################################
# Run OLS and IV by NAICS 2-Digit Sector #
##########################################

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full.csv"), header = TRUE)

# Merge HP Filtered birthrates back into main data frame
df <- merge(df, births_hp, by = c("statefips", "year", "naics2"), all.x = TRUE) %>%
    filter(naics2 != "")
# Restrict to 1979-2007 for replication
panel07 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_d_sh_under5_hp", "l20_birthrate_hp",
    "dln_wap", "l20_d_sh_under5", "l20_birthrate.x"), as.double)) %>%
    mutate(l2_dln_wap_hp = lag(dln_wap_hp, 2), l22_sh_under5_hp = lag(l20_sh_under5_hp, 2))

# Run OLS regression (w/ FE)
ols_model <- feols(bds_sr_hp ~ l2_dln_wap_hp | statefips + year, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))
etable(ols_model)

# If you prefer, you can use lapply instead of a loop
ols_estimates <- lapply(ols_model, function(ols_model) coeftable(ols_model))

# Combine the coefficient estimates into a data frame for easier visualization
ols_table <- as.data.frame(do.call(rbind, ols_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

# Export as a CSV
outpath <- "output/tables/"
write.csv(ols_table, file.path(outpath, "ols_table_L2.csv"), row.names = FALSE)

# Run IV regression (w/ FE) Using l20_sh_under5_hp as an instrument
iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | l2_dln_wap_hp ~ l22_sh_under5_hp, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))
etable(iv_model)

iv_estimates <- lapply(iv_model, function(iv_model) coeftable(iv_model))

# Combine the coefficient estimates into a data frame for easier visualization
iv_table <- as.data.frame(do.call(rbind, iv_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

# Export as a CSV
write.csv(iv_table, file.path(outpath, "iv_table_L2.csv"), row.names = FALSE)
