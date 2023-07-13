library(dplyr)
library(ggplot2)


# Making plots of the BDS-DataAxle merged data
setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/")
m <- read.csv("processed-data/bds_axle_ts.csv", header=TRUE)

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