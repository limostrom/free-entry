library(dplyr)
library(haven)
library(tools)
library(tidyr)
library(plm)
library(broom)
library(AER)
library(mFilter)
library(fixest)


setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_state_rank.csv"), header = TRUE) %>%
    filter(year >= 1980 & year <= 2007)


# Read in dataframe
fd <- read.csv(file.path(filepath, "regs_state_rank_fd.csv"), header = TRUE) %>%
    filter(year >= 1980 & year <= 2007) %>%
    mutate(across(c("sr_fd", "wapgr_fd"), as.double))

# Ranks 1-10
grp1 <- df %>%
    filter(st_restr_rank <= 10)
# Ranks 11-20
grp2 <- df %>%
    filter(st_restr_rank > 10 & st_restr_rank <= 20)
# Ranks 21-30
grp3 <- df %>%
    filter(st_restr_rank > 20 & st_restr_rank <= 30)
# Ranks 31-40
grp4 <- df %>%
    filter(st_restr_rank > 30 & st_restr_rank <= 40)
# Ranks 41-51
grp5 <- df %>%
    filter(st_restr_rank > 40)

fd1 <- fd %>%
    filter(st_restr_rank <= 10)
fd2 <- fd %>%
    filter(st_restr_rank > 10 & st_restr_rank <= 20)
fd3 <- fd %>%
    filter(st_restr_rank > 20 & st_restr_rank <= 30)
fd4 <- fd %>%
    filter(st_restr_rank > 30 & st_restr_rank <= 40)
fd5 <- fd %>%
    filter(st_restr_rank > 40)

# Regs by group
## Group 1
    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = grp1,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]
    ols_p <- summary(ols_model)$coeftable[4]

    # FD 
    fd_model <- feols(sr_fd ~ wapgr_fd | year, data = fd1,
                cluster = c("statefips", "year"))
    fd_coeff <- summary(fd_model)$coeftable[1]
    fd_se <- summary(fd_model)$coeftable[2]
    fd_p <- summary(fd_model)$coeftable[4]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = grp1,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]
    iv_p <- summary(iv_model)$coeftable[4]
    summary(iv_model, stage=1)
    # Output
    out1 <- c(1, ols_coeff, ols_se, ols_p, fd_coeff, fd_se, fd_p, iv_coeff, iv_se, iv_p)
## Group 2
    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = grp2,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]
    ols_p <- summary(ols_model)$coeftable[4]


    # FD 
    fd_model <- feols(sr_fd ~ wapgr_fd | year, data = fd2,
                cluster = c("statefips", "year"))
    fd_coeff <- summary(fd_model)$coeftable[1]
    fd_se <- summary(fd_model)$coeftable[2]
    fd_p <- summary(fd_model)$coeftable[4]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = grp2,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]
    iv_p <- summary(iv_model)$coeftable[4]
    summary(iv_model, stage=1)

    # Output
    out2 <- c(2, ols_coeff, ols_se, ols_p, fd_coeff, fd_se, fd_p, iv_coeff, iv_se, iv_p)
## Group 3
    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = grp3,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]
    ols_p <- summary(ols_model)$coeftable[4]

    # FD 
    fd_model <- feols(sr_fd ~ wapgr_fd | year, data = fd3,
                cluster = c("statefips", "year"))
    fd_coeff <- summary(fd_model)$coeftable[1]
    fd_se <- summary(fd_model)$coeftable[2]
    fd_p <- summary(fd_model)$coeftable[4]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = grp3,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]
    iv_p <- summary(iv_model)$coeftable[4]
    summary(iv_model, stage=1)

    # Output
    out3 <- c(3, ols_coeff, ols_se, ols_p, fd_coeff, fd_se, fd_p, iv_coeff, iv_se, iv_p)
## Group 4
    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = grp4,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]
    ols_p <- summary(ols_model)$coeftable[4]

    # FD 
    fd_model <- feols(sr_fd ~ wapgr_fd | year, data = fd4,
                cluster = c("statefips", "year"))
    fd_coeff <- summary(fd_model)$coeftable[1]
    fd_se <- summary(fd_model)$coeftable[2]
    fd_p <- summary(fd_model)$coeftable[4]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = grp4,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]
    iv_p <- summary(iv_model)$coeftable[4]
    summary(iv_model, stage=1)

    # Output
    out4 <- c(4, ols_coeff, ols_se, ols_p, fd_coeff, fd_se, fd_p, iv_coeff, iv_se, iv_p)
## Group 5
    # OLS 
    ols_model <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = grp5,
                cluster = c("statefips", "year"))
    ols_coeff <- summary(ols_model)$coeftable[1]
    ols_se <- summary(ols_model)$coeftable[2]
    ols_p <- summary(ols_model)$coeftable[4]

    # FD 
    fd_model <- feols(sr_fd ~ wapgr_fd | year, data = fd5,
                cluster = c("statefips", "year"))
    fd_coeff <- summary(fd_model)$coeftable[1]
    fd_se <- summary(fd_model)$coeftable[2]
    fd_p <- summary(fd_model)$coeftable[4]

    # IV
    iv_model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp, data = grp5,
                cluster = c("statefips", "year"))
    iv_coeff <- summary(iv_model)$coeftable[1]
    iv_se <- summary(iv_model)$coeftable[2]
    iv_p <- summary(iv_model)$coeftable[4]
    summary(iv_model, stage=1)

    # Output
    out5 <- c(5, ols_coeff, ols_se, ols_p, fd_coeff, fd_se, fd_p, iv_coeff, iv_se, iv_p)

    out <- rbind(out1, out2, out3, out4, out5)

out <- as.data.frame(out) %>%
    rename(group = V1, ols_coeff = V2, ols_se = V3, ols_p = V4,
            fd_coeff = V5, fd_se = V6, fd_p = V7, iv_coeff = V8, iv_se = V9, iv_p = V10) %>%
    mutate(across(c("group", "ols_coeff", "ols_se", "ols_p",
            "fd_coeff", "fd_se", "fd_p", "iv_coeff", "iv_se", "iv_p"), as.double))

#save as csv
filepath <- "output/tables"
write.csv(out, file.path(filepath, "state_rank_regs.csv"), row.names = FALSE)
