# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)
library(tidyr)

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/intercensal_pop/"

# Read in 1970 population data for imputing 1960 intercensal numbers
fwf <- fwf_widths(c(2, 3, 10, 8))
census70 <- read_fwf(paste0(filepath, "e7080sta.txt"), fwf, skip=14)
colnames(census70) <- c("statefips", "statename", "agegrp", "pop")

census70 <- census70 %>%
    select(statefips, agegrp, pop) %>%
    pivot_wider(names_from = agegrp, values_from = pop) %>%
    select(-`NA`)

# Compute pop under age 5 for instrument
census70 <- census70 %>%
    mutate(year = 1970,
        pop_under5 = `0-2` + `3-4`,
        pop = rowSums(select(., `0-2`:`65+`)),
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, pop_under5, pop)

write.csv(census70, paste0(filepath, "census70.csv"), row.names = FALSE)
