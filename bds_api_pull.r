library(httr)
library(jsonlite)

# Set the API key and construct the base URL
api_key <- "a9849ca3e1f42d9273a95763547efb5db955c261"
base_url <- "https://api.census.gov/data/timeseries/bds"

outfolder <-"/Users/laurenmostrom/Library/CloudStorage/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/raw-data/bds/"

# Define the desired variables and filters
variables <- c("NAME", "NAICS_LABEL", "YEAR", "FAGE", "FIRM", "ESTAB", "EMP")

years <- c(1979:2019)
# Note: dropping public administration (92) and unclassified (99) from the NAICS codes
inds <- c("00", 11, 21, 22, 23, "31-33", 42, "44-45", "48-49", 51, 52, 53, 54, 55, 56, 61, 62, 71, 72, 81)

#Pull firms (all ages) by year, national totals
for (y in years) {
    # Construct the full URL with parameters
    url <- paste0(base_url, "?get=", paste(variables, collapse = ","), "&for=us:1&time=", y, "&key=", api_key)

    # Send the HTTP GET request and parse the response
    response <- GET(url)
    d <- fromJSON(content(response, "text"))
    
    # Remove the first row (header)
    d <- d[-1, ]
    d <- as.data.frame(d)

    # Write to CSV
    write.csv(d, paste0(outfolder, "bds_tot_", y, ".csv"))

    Sys.sleep(1)
}

# Pull firms age 0 by year, NAICS 2-digit sector, and MSA
for (i in inds) {
    for (y in years) {
        # Construct the full URL with parameters
        url <- paste0(base_url, "?get=", paste(variables, collapse = ","), "&for=state:*&time=", y, "&NAICS=", i, "&key=", api_key)

        # Send the HTTP GET request and parse the response
        response <- GET(url)
        d <- fromJSON(content(response, "text"))
        
        # Remove the first row (header)
        d <- d[-1, ]
        d <- as.data.frame(d)

        # Write to CSV
        write.csv(d, paste0(outfolder, "bds_", y, "_", i, ".csv"))

        Sys.sleep(1)
    }
}

