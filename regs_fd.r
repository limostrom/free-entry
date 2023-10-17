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
# Run FD Regs by NAICS 2-Digit Sector #
##########################################

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "processed-data"

# Read in dataframe
df <- read.csv(file.path(filepath, "regs_full_fd.csv"), header = TRUE)

# Split into 1980-2007 and 2008-2019
panel80 <- df %>%
    filter(year >= 1980 & year <= 2007)
panel19 <- df %>%
    filter(year >= 2008 & year <= 2019)

# Run FD Regs
fd_regs <- feols(sr_fd ~ wapgr_fd |  year,
                 data = panel80, cluster = c("statefips", "year"))
etable(fd_regs)

fd19_regs <- feols(sr_fd ~ wapgr_fd |  year,
                 data = panel19, cluster = c("statefips", "year"))
etable(fd19_regs)