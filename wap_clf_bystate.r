# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)
library(tidyr)

###############
# WAP for RHS #
###############

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/intercensal_pop/"

# 1970-1979 ================================================================
fwf <- fwf_widths(c(2, 3, 10, rep(8,11)))
ic70 <- read_fwf(paste0(filepath, "e7080sta.txt"), fwf, skip=14)
colnames(ic70) <- c("statefips", "statename", "agegrp",
        "1970", "1971", "1972", "1973", "1974",
        "1975", "1976", "1977", "1978", "1979", "1980")
ic70 <- ic70 %>%
    select(statefips, agegrp, `1970`:`1980`) %>%
    pivot_longer(cols = `1970`:`1980`, names_to = "year", values_to = "pop") %>%
    mutate(year = as.numeric(year)) %>%
    pivot_wider(names_from = agegrp, values_from = pop) %>%
    select(-`NA`)

# Compute wap (age 20-64) by state
wap70 <- ic70 %>%
    mutate(wap = rowSums(select(., `20`:`62-64F`)),
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, wap)

# Compute pop under age 5 for instrument
iv70 <- ic70 %>%
    mutate(year = year + 20,
        L20_pop_under5 = `0-2` + `3-4`,
        L20_pop = rowSums(select(., `0-2`:`65+`)),
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, L20_pop_under5, L20_pop)

# 1980-1989 ================================================================
fwf <- fwf_widths(c(2, 1, 1, 1, rep(7,18)))
ic80 <- read_fwf(paste0(filepath, "st_int_asrh.txt"), fwf)
ic80 <- ic80 %>%
        mutate(year = 1980 + X2) %>%
        rename(statefips = X1, raceth = X3, sex = X4,
            `0` = X5, `5` = X6, `10` = X7, `15` = X8, `20` = X9, `25` = X10,
            `30` = X11, `35` = X12, `40` = X13, `45` = X14, `50` = X15,
            `55` = X16, `60` = X17, `65` = X18, `70` = X19, `75` = X20,
            `80` = X21, `85` = X22) %>%
        pivot_longer(cols = `0`:`85`, names_to = "agegrp", values_to = "pop") %>%
        select(year, statefips, agegrp, pop) %>%
        group_by(year, statefips, agegrp) %>%
        mutate(pop = sum(pop)) %>%
        ungroup() %>%
        distinct()

# Compute wap (age 20-64) by state
wap80 <- ic80 %>%
    select(year, statefips, agegrp, pop) %>%
    mutate(agegrp = as.numeric(agegrp)) %>%
    filter(agegrp >= 20 & agegrp < 65) %>%
    group_by(year, statefips) %>%
    mutate(wap = sum(pop)) %>%
    ungroup() %>%
    distinct() %>%
    mutate(statefips = as.numeric(statefips)) %>%
    select(year, statefips, wap)

# Compute pop under age 5 for instrument
iv80 <- ic80 %>%
    select(year, statefips, agegrp, pop) %>%
    group_by(year, statefips, agegrp) %>%
    mutate(pop = sum(pop)) %>%
    ungroup() %>%
    distinct() %>%
    pivot_wider(names_from = agegrp, values_from = pop) %>%
    mutate(year = year + 20,
        L20_pop_under5 = `0`,
        L20_pop = `0` + `5` + `10` + `15` + `20` + `25` + `30` + `35` + `40` + `45` + `50` + `55` + `60` + `65` + `70` + `75` + `80` + `85`,
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, L20_pop, L20_pop_under5)

# 1990-1999 ================================================================
years <- c(1990:1999)
fwf <- fwf_widths(c(2, 4, 3, 3, 2, 2, 7))

filenames <- list.files(path = filepath, pattern = "stch-icen\\d{4}.txt", 
                         full.names = TRUE)
ic90 <- lapply(filenames, read_fwf, fwf)
ic90 <- do.call(rbind, ic90) %>%
        mutate(across("X1":"X7", as.numeric), X1 = 1900 + X1) %>%
        rename(year = X1, statefips = X2, countyfips = X3,
               agegrp = X4, sexrace = X5, ethn = X6, pop = X7)

# Compute wap (age 20-64) by state
wap90 <- ic90 %>%
    select(year, statefips, agegrp, pop) %>%
    filter(agegrp >= 5 & agegrp <= 13) %>%
    group_by(year, statefips) %>%
    mutate(wap = sum(pop)) %>%
    ungroup() %>%
    distinct() %>%
    mutate(statefips = as.numeric(statefips)) %>%
    select(year, statefips, wap)

# Compute pop under age 5 for instrument
iv90 <- ic90 %>%
    select(year, statefips, agegrp, pop) %>%
    group_by(year, statefips, agegrp) %>%
    mutate(pop = sum(pop)) %>%
    ungroup() %>%
    distinct() %>%
    pivot_wider(names_from = agegrp, values_from = pop) %>%
    mutate(year = year + 20,
        across(c("0":"18"), as.numeric),
        L20_pop_under5 = `0` + `1`,
        L20_pop = `0` + `1` + `2` + `3` + `4` + `5` + `6` + `7` + `8` + `9` + `10` + `11` + `12` + `13` + `14` + `15` + `16` + `17` + `18`,
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, L20_pop, L20_pop_under5)

# 2000-2004 ================================================================
filepath <- "raw-data/acs_pop/"
# Open intercensal estimates for 2004
ic00 <- read.csv(paste0(filepath, "co-est00int-agesex-5yr.csv"), header = TRUE)
# Select only the columns we need
ic00 <- ic00 %>%
        filter(SEX == 0) %>%
        select(STATE, AGEGRP, ESTIMATESBASE2000, POPESTIMATE2001,
            POPESTIMATE2002, POPESTIMATE2003, POPESTIMATE2004) %>%
        filter(AGEGRP >= 5 & AGEGRP <= 13)
# Rename the columns
colnames(ic00) <- c("statefips", "agegrp", "2000", "2001", "2002", "2003", "2004")
# Reshape ic from wide to long format
ic00 <- pivot_longer(ic00, cols = c("2000":"2004"),
    names_to = "year", values_to = "pop")
# Reshape long to wide on agegrp and take rowsum
wap00 <- ic00 %>%
    mutate(statefips = as.numeric(statefips)) %>%
    select(year, statefips, agegrp, pop) %>%
    group_by(year, statefips, agegrp) %>%
    mutate(pop = sum(pop)) %>%
    ungroup() %>%
    distinct() %>%
    pivot_wider(names_from = agegrp, values_from = pop) %>%
    mutate(across(`5`:`13`, as.numeric),
        wap = `5` + `6` + `7` + `8` + `9` + `10` + `11` + `12` + `13`,
        statefips = as.numeric(statefips)) %>%
    select(year, statefips, wap)

# 2005-2019 ================================================================
filepath <- "raw-data/acs_pop/"
years <- c(2005:2019)
acs_list <- list()
for (y in years) {
    acs <- read_csv(paste0(filepath, "acs_state_", y, ".csv")) %>%
        rename(statefips = GEOID, statename = NAME) %>%
        mutate(year = y, statefips = as.numeric(statefips)) %>%
        select(year, statefips, wap)
    acs_list[[length(acs_list) + 1]] <- acs
}
wap05 <- bind_rows(acs_list)

wap <- rbind(wap70, wap80, wap90, wap00, wap05) %>%
        filter(!is.na(statefips)) %>%
        distinct() %>%
        group_by(statefips) %>%
        mutate(wap_hp = hpfilter(wap, freq = 6.25)$trend,
            wap_hp = as.vector(wap_hp)) %>%
        ungroup()

iv <- rbind(iv70, iv80, iv90) %>%
        filter(!is.na(statefips)) %>%
        distinct() %>%
        group_by(statefips) %>%
        mutate(L20_pop_under5_hp = hpfilter(L20_pop_under5, freq = 6.25)$trend,
            L20_pop_hp = hpfilter(L20_pop, freq = 6.25)$trend,
            L20_pop_under5_hp = as.vector(L20_pop_under5_hp),
            L20_pop_hp = as.vector(L20_pop_hp)) %>%
        ungroup()

# Merge WAP and IV on year and statefips and run HP filter
rhs <- merge(wap, iv, by = c("year", "statefips"), all.x = TRUE) %>%
    mutate(statefips = as.numeric(statefips),
            year = as.numeric(year))
            
write.csv(rhs, "processed-data/rhs_bystate.csv", row.names = FALSE)