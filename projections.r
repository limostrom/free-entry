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

# Sum up firms by state and year, drop duplicates
agg <- df %>%
    filter(statefips != 72) %>%
    group_by(statefips, year) %>%
    mutate(tot_hp = sum(bds_tot_hp), age0_hp = sum(bds_age0_hp)) %>%
    ungroup() %>%
    select(statefips, year, tot_hp, age0_hp, dln_wap_hp, l20_sh_under5_hp) %>%
    mutate(bds_sr_hp = age0_hp / tot_hp) %>%
    distinct() %>%
    mutate(t = year - 1979)
agg07 <- agg %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))
agg19 <- agg %>%
    filter(year >= 2008 & year <= 2019) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))

# Save a construction-only df
constr <- df %>%
    filter(naics2 == "23") %>%
    mutate(t = year - 1979)

constr07 <- constr %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))
constr19 <- constr %>%
    filter(year >= 2008 & year <= 2019) %>%
    mutate(across(c("dln_wap_hp", "l20_sh_under5_hp"), as.double))


# OLS (Aggregate)
ols_agg <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = agg07,
                 cluster = c("statefips", "year"))
etable(ols_agg)
# Run IV regression with state fixed effects
iv_agg <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = agg07)
etable(iv_agg)
# Try Poisson
pois_agg <- fepois(bds_sr_hp ~ dln_wap_hp + t | statefips,
            data = agg07, cluster = c("statefips", "year"))

# save predictions
agg07$ols_preds <- predict(ols_agg, newdata = agg07)
agg19$ols_preds <- predict(ols_agg, newdata = agg19)
agg07$iv_preds <- predict(iv_agg, newdata = agg07)
agg19$iv_preds <- predict(iv_agg, newdata = agg19)
agg07$pois_preds <- predict(pois_agg, newdata = agg07)
agg19$pois_preds <- predict(pois_agg, newdata = agg19)
agg <- rbind(agg07, agg19)

# Add coefficients for manual computations
agg <- agg %>%
    mutate(ols_coeff = summary(ols_agg)$coeftable[1],
           iv_coeff = summary(iv_agg)$coeftable[1],
           iv_fs = summary(iv_agg, stage=1)$coeftable[1])

# save as a CSV
write.csv(agg, file.path(filepath, "aggregate_projections.csv"))

ols_con <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = constr07,
                 cluster = c("statefips", "year"))
etable(ols_con)
constr07$ols_preds <- predict(ols_con, newdata = constr07)
constr19$ols_preds <- predict(ols_con, newdata = constr19)

iv_con <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = constr07)
etable(iv_con)
constr07$iv_preds <- predict(iv_con, newdata = constr07)
constr19$iv_preds <- predict(iv_con, newdata = constr19)
constr <- rbind(constr07, constr19)

# Add coefficients for manual computations
constr <- constr %>%
    mutate(ols_coeff = summary(ols_con)$coeftable[1],
           iv_coeff = summary(iv_con)$coeftable[1],
           iv_fs = summary(iv_con, stage=1)$coeftable[1])

# save as a CSV
write.csv(constr, file.path(filepath, "construction_projections.csv"))