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
# Run OLS and IV by Groups of Industries #
##########################################

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in dataframe for Regulation Index
df <- read.csv(file.path(filepath, "regs_naics2_byRegI.csv"), header = TRUE)

# Keep only 1980-2007
panel80 <- df %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))

# Run OLS regression (w/ FE)
ols_reg_model <- feols(bds_sr_hp ~ dln_wap_hp + reg_low + reg_high 
                        + dln_wap_hp:reg_low + dln_wap_hp:reg_high 
                        | statefips + year, data = panel80,
                cluster = c("statefips", "year"))

# Run IV regression (w/ FE)
iv_reg_model <- feols(bds_sr_hp ~ reg_low + reg_high 
                        | statefips + year 
                        | dln_wap_hp + dln_wap_hp:reg_low + dln_wap_hp:reg_high
                        ~ l20_sh_under5_hp + l20_sh_under5_hp:reg_low + l20_sh_under5_hp:reg_high, 
                data = panel80, cluster = c("statefips", "year"))
etable(iv_reg_model)
summary(iv_reg_model, stage=1)

# Read in dataframe for Rajan-Zingales Index
df <- read.csv(file.path(filepath, "regs_naics2_byRZI.csv"), header = TRUE)

# Keep only 1980-2007
panel80 <- df %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))

# Run OLS regression (w/ FE)
ols_rz_model <- feols(bds_sr_hp ~ dln_wap_hp + rz_low + rz_high 
                        + dln_wap_hp:rz_low + dln_wap_hp:rz_high 
                        | statefips + year, data = panel80,
                cluster = c("statefips", "year"))
etable(ols_rz_model)

# Run IV regression (w/ FE)
iv_rz_model <- feols(bds_sr_hp ~ rz_low + rz_high 
                        | statefips + year 
                        | dln_wap_hp + dln_wap_hp:rz_low + dln_wap_hp:rz_high
                        ~ l20_sh_under5_hp + l20_sh_under5_hp:rz_low + l20_sh_under5_hp:rz_high, 
                data = panel80, cluster = c("statefips", "year"))
etable(iv_rz_model)
summary(iv_rz_model, stage=1)