library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(plm)
library(broom)
library(AER)

##########################################
# Replicate Table 6 from KPS: OLS and IV #
##########################################

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in LHS
lhs <- read.csv(file.path(filepath, "lhs_bystate.csv"), header = TRUE)
# Read in RHS
rhs <- read.csv(file.path(filepath, "rhs_bystate.csv"), header = TRUE)
# Merge LHS and RHS
df <- merge(lhs, rhs, by = c("statefips", "year")) %>%
    mutate(across())
    filter(year >= 1990)
# Convert data frame to panel data format
panel <- pdata.frame(df, index = c("naics2", "statefips", "year")) %>%
    mutate(across(c("dln_wap_hp", "L20_d_sh_under5_hp", "dln_wap",
    "L20_d_sh_under5"), as.double))

# Run OLS regression (no FE)
ols_model <- lm(bds_sr_hp ~ dln_wap_hp, data = df)
# Extract coefficients, standard errors, and p-values
ols_tidy <- broom::tidy(ols_model)

# Run IV regression (with FE)
iv_model <- ivreg(bds_sr_hp ~ dln_wap_hp | L20_d_sh_under5_hp, data = df)
# Extract coefficients, standard errors, and p-values
iv_tidy <- broom::tidy(iv_model)

# Save coefficients, standard errors, and p-values to a data frame
results <- data.frame(
  variable = ols_tidy$term,
  ols_coef = ols_tidy$estimate,
  ols_se = ols_tidy$std.error,
  ols_p = ols_tidy$p.value,
  iv_coef = iv_tidy$estimate,
  iv_se = iv_tidy$std.error,
  iv_p = iv_tidy$p.value
)