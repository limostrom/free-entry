# Load only the packages you need
library(dplyr)
library(haven)
library(tools)
library(ggplot2)
library(tidyr)

# Appending BDS files for national totals
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
filepath <- "raw-data/bds"
filenames <- list.files(path = filepath, pattern = "^bds_tot_\\d{4}.csv", full.names = TRUE)
bds <- lapply(filenames, read.csv, header = TRUE)
bds <- do.call(rbind, bds)

# Rename columns
colnames(bds) <- c("rownum","country", "naics2desc", "year", "firmage", "firms", "estabs", "emp", "year2", "ones")

# Remove rownum and year2
bds <- bds %>% select(year, firmage, firms, estabs)
# Keep only firmage == 1 (total) and firmage == 10 (age 0)
bds <- bds %>% filter(firmage %in% c(1, 10))
# Reshape the data
bds_wide <- bds %>%
  pivot_wider(names_from = firmage, values_from = c("firms", "estabs"))

#Read in Infogroup tabs from Stata
procdata <- "processed-data/startup_rates"

axlefiles <- list.files(path = procdata, pattern = "^a.*_sr.dta", full.names = TRUE)
axle <- lapply(axlefiles, read_dta)
axle <- do.call(rbind, axle)

# Merge bds with dataaxle
merged <- merge(bds_wide, axle, by = "year")
colnames(merged) <- c("year", "bds_firms_tot", "bds_firms_age0", 
            "bds_estabs_tot", "bds_estabs_age0", "axle_firms_age0",
            "axle_firms_tot", "axle_sr")
merged$bds_firms_mns <- merged$bds_firms_tot/1000000
merged$bds_firms_age0_ths <- merged$bds_firms_age0/1000
merged$axle_firms_mns <- merged$axle_firms_tot/1000000
merged$axle_firms_age0_ths <- merged$axle_firms_age0/1000
# Compute startup rate for BDS
merged$bds_sr <- merged$bds_firms_age0/merged$bds_firms_tot * 100
merged$axle_sr <- merged$axle_sr * 100


# Create a line plot of total firms by year
plot1 <- ggplot(merged, aes(x = year)) +
  geom_line(aes(y = bds_firms_mns, color = "BDS")) +
  geom_line(aes(y = axle_firms_mns, color = "DataAxle")) +
  labs(x = "Year", y = "Total Firms (Millions)", color = "") +
  scale_color_manual(values = c("BDS" = "#2a2a2a", "DataAxle" = "blue")) +
  scale_y_continuous(limits = c(0, NA)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14),
        legend.position = "bottom",
        legend.box = "horizontal",
        legend.margin = margin(t = 0, r = 0, b = 0, l = 0),
        legend.text = element_text(size = 12),
        axis.line = element_line(color = "black", linewidth = 0.5)) +
  guides(color = guide_legend(override.aes = list(shape = c(1, 1), size = 4)))
# Export the plot as a PDF
ggsave("output/bds_comparison_total.pdf", plot1, width = 8, height = 6)


# Create a line plot of new firms by year
plot2 <- ggplot(merged, aes(x = year)) +
  geom_line(aes(y = bds_firms_age0_ths, color = "BDS")) +
  geom_line(aes(y = axle_firms_age0_ths, color = "DataAxle")) +
  labs(x = "Year", y = "New Firms (Thousands)", color = "") +
  scale_color_manual(values = c("BDS" = "#2a2a2a", "DataAxle" = "blue")) +
  scale_y_continuous(limits = c(0, NA)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14),
        legend.position = "bottom",
        legend.box = "horizontal",
        legend.margin = margin(t = 0, r = 0, b = 0, l = 0),
        legend.text = element_text(size = 12),
        axis.line = element_line(color = "black", linewidth = 0.5)) +
  guides(color = guide_legend(override.aes = list(shape = c(1, 1), size = 4)))
# Export the plot as a PDF
ggsave("output/bds_comparison_age0.pdf", plot2, width = 8, height = 6)

# Create a line plot of startup by year
plot3 <- ggplot(merged, aes(x = year)) +
  geom_line(aes(y = bds_sr, color = "BDS")) +
  geom_line(aes(y = axle_sr, color = "DataAxle")) +
  labs(x = "Year", y = "Startup Rate (%)", color = "") +
  scale_color_manual(values = c("BDS" = "#2a2a2a", "DataAxle" = "blue")) +
  scale_y_continuous(limits = c(0, NA)) +
  theme(panel.background = element_rect(fill = "white"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14),
        legend.position = "bottom",
        legend.box = "horizontal",
        legend.margin = margin(t = 0, r = 0, b = 0, l = 0),
        legend.text = element_text(size = 12),
        axis.line = element_line(color = "black", linewidth = 0.5)) 
# Export the plot as a PDF
ggsave("output/bds_comparison_sr.pdf", plot3, width = 8, height = 6)