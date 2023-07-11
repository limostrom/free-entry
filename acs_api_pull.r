# Load the tidycensus package
library(tidycensus)

# Set the API key (replace "YOUR_API_KEY" with your own key)
census_api_key("a9849ca3e1f42d9273a95763547efb5db955c261")

# Set export directory
outfolder <-"/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/raw-data/acs_pop/"

# The regular 1-year ACS for 2020 was not released and is not available in tidycensus.
years <- c(2005:2019, 2021)

# Download population by age for all MSAs in the United States
for (y in years) {
    msa_pop <- get_acs(geography = "metropolitan statistical area/micropolitan statistical area",
                    variables = c("B01001_001", "B01001_003", "B01001_004", "B01001_005", "B01001_006", "B01001_027", "B01001_028", "B01001_029", "B01001_030", "B01001_031"),
                    year = y,
                    survey = "acs1",
                    county = "*",
                    geometry = FALSE)

    # Write to CSV
    write.csv(msa_pop, paste0(outfolder, "acs_", y, ".csv"))

    Sys.sleep(2)
}
