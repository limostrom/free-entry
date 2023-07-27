# Load the tidycensus package
library(tidycensus)
library(tidyr)
library(dplyr)

# Set the API key (replace "YOUR_API_KEY" with your own key)
census_api_key("a9849ca3e1f42d9273a95763547efb5db955c261")

# Set export directory
outfolder <-"/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/raw-data/acs_pop/"

# The regular 1-year ACS for 2020 was not released and is not available in tidycensus.
years <- c(2010:2019)

# Download all variables for the 2019 ACS 1-year estimates
all_vars_acs1 <- load_variables(year = 2019, dataset = "acs1")

# Load the available variables for PEP estimates for the year 2004
variables <- load_variables(2004, "dp")

# Download population by age by state
for (y in years) {
    state_pop <- get_acs(geography = "state",
                    variables = c("B01001_008", "B01001_009", "B01001_010",
                                "B01001_011", "B01001_012", "B01001_013",
                                "B01001_014","B01001_015", "B01001_016",
                                "B01001_017", "B01001_018", "B01001_019",
                                "B01001_032", "B01001_033", "B01001_034",
                                "B01001_035", "B01001_036", "B01001_037",
                                "B01001_038", "B01001_039", "B01001_040",
                                "B01001_041", "B01001_042", "B01001_043"),
                    year = 2019,
                    survey = "acs1",
                    county = "17031",
                    geometry = FALSE)

    #Drop margin of error columns
    state_pop <- state_pop %>% select(-moe)

    # Reshape state_pop from long to wide format
    state_pop_wide <- pivot_wider(state_pop,
                    names_from = "variable", values_from = "estimate")

    # Generate working-age population as sum of all the variables pulled from API
    state_pop_wide <- state_pop_wide %>%
        mutate(wap = rowSums(select(., starts_with("B01001")))) %>%
        select(GEOID, NAME, wap)

    # Write to CSV
    write.csv(state_pop_wide, paste0(outfolder, "acs_state_", 2019, ".csv"))

    Sys.sleep(2)
}

# Download population by age for all MSAs in the United States
for (y in years) {
    msa_pop <- get_acs(geography = "metropolitan statistical area/micropolitan statistical area",
                    variables = c("B01001_008", "B01001_009", "B01001_010",
                                "B01001_011", "B01001_012", "B01001_013",
                                "B01001_014","B01001_015", "B01001_016",
                                "B01001_017", "B01001_018", "B01001_019",
                                "B01001_032", "B01001_033", "B01001_034",
                                "B01001_035", "B01001_036", "B01001_037",
                                "B01001_038", "B01001_039", "B01001_040",
                                "B01001_041", "B01001_042", "B01001_043"),
                    year = y,
                    survey = "acs1",
                    county = "*",
                    geometry = FALSE)

    #Drop margin of error columns
    msa_pop <- msa_pop %>% select(-moe)

    # Reshape msa_pop from long to wide format
    msa_pop_wide <- pivot_wider(msa_pop,
                    names_from = "variable", values_from = "estimate")

    # Generate working-age population as sum of all the variables pulled from API
    msa_pop_wide <- msa_pop_wide %>%  
        mutate(wap = rowSums(select(., starts_with("B01001")))) %>%
        select(GEOID, NAME, wap)

    # Write to CSV
    write.csv(msa_pop_wide, paste0(outfolder, "acs_cbsa_", y, ".csv"))

    Sys.sleep(2)
}

# Download population by age for all United States
for (y in years) {
    msa_pop <- get_acs(geography = "us",
                    variables = c("B01001_008", "B01001_009", "B01001_010",
                                "B01001_011", "B01001_012", "B01001_013",
                                "B01001_014","B01001_015", "B01001_016",
                                "B01001_017", "B01001_018", "B01001_019",
                                "B01001_032", "B01001_033", "B01001_034",
                                "B01001_035", "B01001_036", "B01001_037",
                                "B01001_038", "B01001_039", "B01001_040",
                                "B01001_041", "B01001_042", "B01001_043"),
                    year = y,
                    survey = "acs1",
                    county = "*",
                    geometry = FALSE)

    #Drop margin of error columns
    msa_pop <- msa_pop %>% select(-moe)

    # Reshape msa_pop from long to wide format
    msa_pop_wide <- pivot_wider(msa_pop,
                    names_from = "variable", values_from = "estimate")

    # Generate working-age population as sum of ages 20-64
    msa_pop_wide <- msa_pop_wide %>%  
        mutate(wap = rowSums(select(., starts_with("B01001")))) %>%
        select(GEOID, NAME, wap)
    msa_pop_wide$year <- y

    # Write to CSV
    write.csv(msa_pop_wide, paste0(outfolder, "acs_natl_", y, ".csv"))

    Sys.sleep(2)
}