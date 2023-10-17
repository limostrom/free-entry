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

# Apply the HP filter to L20_birthrate
births_hp <- df %>%
    select(statefips, year, naics2, l20_birthrate) %>%
    filter(naics2 != "" & year >= 1988 & year <= 2007) %>%
    group_by(naics2, statefips) %>%
    mutate(l20_birthrate_hp = hpfilter(l20_birthrate, freq = 6.25)$trend) %>%
    ungroup()
# Merge HP Filtered birthrates back into main data frame
df <- merge(df, births_hp, by = c("statefips", "year", "naics2"), all.x = TRUE) %>%
    filter(naics2 != "")
# Restrict to 1979-2007 for replication
panel07 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_d_sh_under5_hp", "l20_birthrate_hp",
    "dln_wap", "l20_d_sh_under5", "l20_birthrate.x"), as.double))
panel19 <- df %>%
    filter(year >= 2008 & year <= 2019) %>%
    mutate(across(c("dln_wap_hp", "l20_d_sh_under5_hp", "l20_birthrate_hp",
    "l20_d_sh_under5", "l20_birthrate.x"), as.double)) %>%
    select(statefips, year, naics2, dln_wap_hp, bds_sr_hp, l20_sh_under5_hp)

# Run OLS regression (w/ FE)
ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))
etable(ols_model)
ols_projections <- predict(ols_model, newdata = panel19)

ols19_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel19,
                split = ~naics2, cluster = c("statefips", "year"))
# If you prefer, you can use lapply instead of a loop
ols_estimates <- lapply(ols_model, function(ols_model) coeftable(ols_model))
ols19_estimates <- lapply(ols19_model, function(ols19_model) coeftable(ols19_model))

# Combine the coefficient estimates into a data frame for easier visualization
ols_table <- as.data.frame(do.call(rbind, ols_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

ols19_table <- as.data.frame(do.call(rbind, ols19_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))
# Export as a CSV
outpath <- "output/tables/"
write.csv(ols_table, file.path(outpath, "ols_table.csv"), row.names = FALSE)
write.csv(ols19_table, file.path(outpath, "ols_table_08-19.csv"), row.names = FALSE)


# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full_fd.csv"), header = TRUE)

# Restrict to 1979-2007 for replication
panel07 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("sr_fd", "wapgr_fd"), as.double)) %>%
    select(statefips, year, naics2, sr_fd, wapgr_fd)
panel19 <- df %>%
    filter(year >= 2008 & year <= 2019) %>%
    mutate(across(c("sr_fd", "wapgr_fd"), as.double)) %>%
    select(statefips, year, naics2, sr_fd, wapgr_fd)

# Run OLS regression (w/ FE)
fd_model <- feols(sr_fd ~ wapgr_fd |  year, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))

fd19_model <- feols(sr_fd ~ wapgr_fd | year, data = panel19,
                split = ~naics2, cluster = c("statefips", "year"))
# If you prefer, you can use lapply instead of a loop
fd_estimates <- lapply(fd_model, function(fd_model) coeftable(fd_model))
fd19_estimates <- lapply(fd19_model, function(fd19_model) coeftable(fd19_model))

# Combine the coefficient estimates into a data frame for easier visualization
fd_table <- as.data.frame(do.call(rbind, fd_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

fd19_table <- as.data.frame(do.call(rbind, fd19_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))
# Export as a CSV
outpath <- "output/tables/"
write.csv(fd_table, file.path(outpath, "fd_table.csv"), row.names = FALSE)
write.csv(fd19_table, file.path(outpath, "fd_table_08-19.csv"), row.names = FALSE)

# Run IV regression (w/ FE) Using l20_sh_under5_hp as an instrument
iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))
etable(iv_model)

iv19_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = panel19,
                split = ~naics2, cluster = c("statefips", "year"))

iv_estimates <- lapply(iv_model, function(iv_model) coeftable(iv_model))
iv19_estimates <- lapply(iv19_model, function(iv19_model) coeftable(iv19_model))

# Combine the coefficient estimates into a data frame for easier visualization
iv_table <- as.data.frame(do.call(rbind, iv_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

iv19_table <- as.data.frame(do.call(rbind, iv19_estimates)) %>%
    rename(estimate = Estimate, std_error = 'Std. Error') %>%
    mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
        "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
        "Information", "Finance and Insurance", "Real Estate",
        "Professional Services", "Management", "Administrative and Support Services",
        "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

# Export as a CSV
write.csv(iv_table, file.path(outpath, "iv_table_under5.csv"), row.names = FALSE)
write.csv(iv19_table, file.path(outpath, "iv_table_under5_08-19.csv"), row.names = FALSE)

# Run IV regression (w/ FE) Using l20_birthrate_hp as an instrument
iv_model2 <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_birthrate_hp, data = panel07,
                split = ~naics2, cluster = c("statefips", "year"))

etable(iv_model2)

iv_estimates2 <- lapply(iv_model2, function(iv_model2) coeftable(iv_model2))

# Combine the coefficient estimates into a data frame for easier visualization
iv_table2 <- as.data.frame(do.call(rbind, iv_estimates2)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(naics2short = c("Agriculture", "Mining", "Utilities", "Construction",
    "Manufacturing", "Wholesale Trade", "Retail Trade", "Transportation and Warehousing",
    "Information", "Finance and Insurance", "Real Estate",
    "Professional Services", "Management", "Administrative and Support Services",
    "Educational Services", "Health Care", "Arts and Entertainment", "Accommodation and Food", "Other Services"))

# Export as a CSV
write.csv(iv_table2, file.path(outpath, "iv_table_birthrate.csv"), row.names = FALSE)



##########################################
# Run OLS and IV by NAICS 2-Digit Sector #
##########################################

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full_sic1_fd.csv"), header = TRUE) %>%
        rename(sic1 = mode_sic1)

# Restrict to 1979-2007 for replication
panel07 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("wapgr_fd", "sr_fd"), as.double))

# Run OLS regression (w/ FE)
fd_model <- feols(sr_fd ~ wapgr_fd | year, data = panel07,
                split = ~sic1, cluster = c("statefips", "year"))
etable(fd_model)

# If you prefer, you can use lapply instead of a loop
fd_estimates <- lapply(fd_model, function(fd_model) coeftable(fd_model))

# Combine the coefficient estimates into a data frame for easier visualization
fd_table <- as.data.frame(do.call(rbind, fd_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error')
fd_table$row_name <- c("Construction", "Manufacturing",
    "Transportation & Utilities", "Trade (Whole & Retail)",
    "Fin., Ins., & Real Estate", "Services")
# Export as a CSV
outpath <- "output/tables/"
write.csv(fd_table, file.path(outpath, "fd_table_sic1.csv"), row.names = FALSE)

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full_sic1.csv"), header = TRUE) %>%
        rename(sic1 = mode_sic1)

# Apply the HP filter to L20_birthrate
births_hp <- df %>%
    select(statefips, year, sic1, l20_birthrate) %>%
    filter(sic1 != "0" & year >= 1988 & year <= 2007) %>%
    group_by(sic1, statefips) %>%
    mutate(l20_birthrate_hp = hpfilter(l20_birthrate, freq = 6.25)$trend) %>%
    ungroup()
# Merge HP Filtered birthrates back into main data frame
df <- merge(df, births_hp, by = c("statefips", "year", "sic1"), all.x = TRUE) %>%
    filter(sic1 != "0")
# Restrict to 1979-2007 for replication
panel07 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp", "l20_birthrate_hp"), as.double))

# Run OLS regression (w/ FE)
ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel07,
                split = ~sic1, cluster = c("statefips", "year"))
etable(ols_model)

# If you prefer, you can use lapply instead of a loop
ols_estimates <- lapply(ols_model, function(ols_model) coeftable(ols_model))

# Combine the coefficient estimates into a data frame for easier visualization
ols_table <- as.data.frame(do.call(rbind, ols_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error')
ols_table$row_name <- c("Construction", "Manufacturing",
    "Transportation & Utilities", "Trade (Whole & Retail)",
    "Fin., Ins., & Real Estate", "Services")
# Export as a CSV
outpath <- "output/tables/"
write.csv(ols_table, file.path(outpath, "ols_table_sic1.csv"), row.names = FALSE)

# Run IV regression (w/ FE) Using l20_sh_under5_hp as an instrument
iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = panel07,
                split = ~sic1, cluster = c("statefips", "year"))
etable(iv_model)

iv_estimates <- lapply(iv_model, function(iv_model) coeftable(iv_model))

# Combine the coefficient estimates into a data frame for easier visualization
iv_table <- as.data.frame(do.call(rbind, iv_estimates)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(row_name = c("Construction", "Manufacturing",
    "Transportation & Utilities", "Trade (Whole & Retail)",
    "Fin., Ins., & Real Estate", "Services"))

# Export as a CSV
write.csv(iv_table, file.path(outpath, "iv_table_under5_sic1.csv"), row.names = FALSE)

# Run IV regression (w/ FE) Using l20_birthrate_hp as an instrument
first2 <- feols(dln_wap_hp ~ l20_birthrate_hp | statefips + year, data = panel07,
                split = ~sic1, cluster = c("statefips", "year"))
iv_model2 <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_birthrate_hp, data = panel07,
                split = ~sic1, cluster = c("statefips", "year"))

etable(iv_model2)

iv_estimates2 <- lapply(iv_model2, function(iv_model2) coeftable(iv_model2))

# Combine the coefficient estimates into a data frame for easier visualization
iv_table2 <- as.data.frame(do.call(rbind, iv_estimates2)) %>%
  rename(estimate = Estimate, std_error = 'Std. Error') %>%
  mutate(row_name = c("Construction", "Manufacturing",
    "Transportation & Utilities", "Trade (Whole & Retail)",
    "Fin., Ins., & Real Estate", "Services"))

# Export as a CSV
write.csv(iv_table2, file.path(outpath, "iv_table_birthrate_sic1.csv"), row.names = FALSE)
