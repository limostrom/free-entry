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

# Sum up firms by state and year, drop duplicates
df <- df %>%
    group_by(statefips, year) %>%
    mutate(tot_hp = sum(bds_tot_hp), age0_hp = sum(bds_age0_hp)) %>%
    ungroup() %>%
    select(statefips, year, tot_hp, age0_hp, dln_wap_hp, l20_birthrate_hp, l20_sh_under5_hp) %>%
    mutate(bds_sr_hp = age0_hp / tot_hp) %>%
    distinct()
# Separate into 2007 and 2019 panels
panel79 <- df %>%
    filter(year >= 1979 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_birthrate_hp", "l20_sh_under5_hp"), as.double))
panel08 <- df %>%
    filter(year >= 2008 & year <= 2019) %>%
    mutate(across(c("dln_wap_hp", "l20_birthrate_hp", "l20_sh_under5_hp"), as.double))
panel80 <- df %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_birthrate_hp", "l20_sh_under5_hp"), as.double))
panel88 <- df %>%
    filter(year >= 1988 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_birthrate_hp", "l20_sh_under5_hp"), as.double))

# Run OLS regression (w/ FE)
ols79_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel79,
                cluster = c("statefips", "year"))
etable(ols79_model)
ols80_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel80,
                cluster = c("statefips", "year"))
etable(ols80_model)
ols88_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel88,
                cluster = c("statefips", "year"))
etable(ols88_model)
ols19_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = panel08,
                cluster = c("statefips", "year"))
etable(ols19_model)

# Run IV regression (w/ FE)
iv80_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp , data = panel80,
                cluster = c("statefips", "year"))
etable(iv80_model)
summary(iv80_model, stage=1)

iv88_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_birthrate_hp , data = panel88,
                cluster = c("statefips", "year"))
etable(iv88_model)
summary(iv88_model, stage=1)

iv08_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp , data = panel08,
                cluster = c("statefips", "year"))
etable(iv08_model)
