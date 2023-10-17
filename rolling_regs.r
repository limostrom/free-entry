library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(plm)
library(broom)
library(AER)
library(mFilter)
library(fixest)

##############################################
# Run Regressions in Rolling 10-year Windows #
##############################################

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full.csv"), header = TRUE)

# Sum up firms by state and year, drop duplicates
agg <- df %>%
    group_by(statefips, year) %>%
    mutate(tot_hp = sum(bds_tot_hp), age0_hp = sum(bds_age0_hp)) %>%
    ungroup() %>%
    select(statefips, year, tot_hp, age0_hp, dln_wap_hp, l20_sh_under5_hp) %>%
    mutate(bds_sr_hp = age0_hp / tot_hp) %>%
    distinct()

# --- Aggregate --- #
rolling <- list()
# Create rolling 10-year windows
for (y in 1989:2019) {
    w <- agg %>%
        filter(year >= y - 9 & year <= y)

    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = w,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = w,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]

    rolling <- rbind(rolling, c(y, ols_coeff, ols_se, iv_coeff, iv_se))
}

rolling <- as.data.frame(rolling) %>%
    rename(year = V1, ols_coeff = V2, ols_se = V3, iv_coeff = V4, iv_se = V5) %>%
    mutate(across(c("year", "ols_coeff", "ols_se", "iv_coeff", "iv_se"), as.double))

#save as csv
write.csv(rolling, file.path(filepath, "rolling_regs.csv"), row.names = FALSE)

# --- First Differences --- #
df <- read.csv(file.path(filepath, "regs_agg_fd.csv"), header = TRUE)

rolling <- list()
# Create rolling 10-year windows
for (y in 1989:2019) {
    w <- df %>%
        filter(year >= y - 9 & year <= y)

    # OLS 
    ols_model <- feols(sr_fd ~ wapgr_fd | year, data = w,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]

    rolling <- rbind(rolling, c(y, ols_coeff, ols_se))
}

rolling <- as.data.frame(rolling) %>%
    rename(year = V1, ols_coeff = V2, ols_se = V3) %>%
    mutate(across(c("year", "ols_coeff", "ols_se"), as.double))

#save as csv
write.csv(rolling, file.path(filepath, "rolling_regs_fd.csv"), row.names = FALSE)

# --- By Sector --- #

df <- read.csv(file.path(filepath, "regs_full_fd.csv"), header = TRUE)

# loop over sectors
indlist <- c("11", "21", "22", "23", "31-33", "42", "44-45", "48-49", "51", "52", "53", "54", "55", "56", "61", "62", "71", "72", "81")

for (i in indlist) {
    subdf <- df %>%
        filter(naics2 == i)

    rolling <- list()
    # Create rolling 10-year windows
    for (y in 1989:2019) {
        w <- subdf %>%
            filter(year >= y - 9 & year <= y)

        # OLS 
        ols_model <- feols(sr_fd ~ wapgr_fd | year, data = w,
                    cluster = c("statefips", "year"))
        ols_coeff <- summary(ols_model)$coeftable[1]
        ols_se <- summary(ols_model)$coeftable[2]

        rolling <- rbind(rolling, c(y, ols_coeff, ols_se))
    }

    rolling <- as.data.frame(rolling) %>%
        rename(year = V1, ols_coeff = V2, ols_se = V3) %>%
        mutate(across(c("year", "ols_coeff", "ols_se"), as.double))

    #save as csv
    write.csv(rolling, paste0(filepath,"/rolling_regs_fd_", i, ".csv"), row.names = FALSE)
}