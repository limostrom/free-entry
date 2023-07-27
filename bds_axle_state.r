# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)
library(tidyr)

#############################
# BDS Startup Rates for LHS #
#############################

# Appending BDS files by state and firm age
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/bds"

years <- c(1979:2019)
inds <- c(11, 21, 22, 23, "31-33", 42, "44-45", "48-49", 51, 52, 53, 54, 55, 56, 61, 62, 71, 72, 81)

# Create an empty list to store the data frames
bds_list <- list()

# Loop over the BDS files and append the data frames to the list
for (y in years) {
for (i in inds) {
    bds <- read_csv(paste0(filepath, "/bds_", y, "_", i, ".csv"))
    colnames(bds) <- c("rownum", "statename", "naics2desc",
        "year", "firmage", "firms", "estabs", "emp", "year2",
        "naics2", "statefips")
    bds <- bds %>%
        select(year, statefips, naics2, firmage, firms) %>%
        mutate(naics2 = as.character(naics2),
        statefips = as.numeric(statefips))
    bds_list[[length(bds_list) + 1]] <- bds
}
}

# Combine the data frames into a single data frame
bds_combined <- bind_rows(bds_list) %>%
    filter(firmage %in% c("001", "010"))
bds <- pivot_wider(bds_combined,
        names_from = firmage, values_from = firms) %>%
        rename(bds_tot = `001`, bds_age0 = `010`)
# Now HP Filter them (lambda=6.25) and comupute startup rates
bds <- bds %>%
    group_by(statefips, naics2) %>%
    mutate(bds_tot_hp = hpfilter(bds_tot, 6.25)$trend,
        bds_age0_hp = hpfilter(bds_age0, 6.25)$trend) %>%
    mutate(bds_sr = bds_age0/bds_tot,
        bds_sr_hp = bds_age0_hp/bds_tot_hp)

##################################
# DataAxle Startup Rates for LHS #
##################################

filepath <- "processed-data/startup_rates/"
st_xwalk <- read_csv("processed-data/states.csv")
naics2_xwalk <- read_csv("processed-data/naics2.csv")

filenames <- list.files(path = filepath, pattern = "ind-state\\d{4}.dta", full.names = TRUE)
axle <- lapply(filenames, read_dta)
axle <- do.call(rbind, axle)
axle <- merge(axle, st_xwalk, by = "state", all.x = TRUE) %>%
    merge(naics2_xwalk, by = "naics2desc", all.x = TRUE) %>%
    mutate(statefips = as.numeric(statefips)) %>%
    select(year, statefips, naics2, new_firm, n_firms) %>%
    rename(axle_age0 = new_firm, axle_tot = n_firms) %>%
    group_by(statefips, naics2) %>%
    mutate(axle_tot_hp = hpfilter(axle_tot, 6.25)$trend,
        axle_age0_hp = hpfilter(axle_age0, 6.25)$trend) %>%
    mutate(axle_sr = axle_age0/axle_tot,
        axle_sr_hp = axle_age0_hp/axle_tot_hp)

# Merge the two data frames
lhs <- merge(bds, axle, by = c("year", "statefips", "naics2"), all.x = TRUE)

write.csv(lhs, "processed-data/lhs_bystate.csv", row.names = FALSE)