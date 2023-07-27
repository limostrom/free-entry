library(fixest)

setwd("~/Dropbox/Personal Document Backup/Booth/Second Year/Y2 Paper/Finance & Dynamism/processed-data/")
df <- read.csv("regs_full.csv", header = TRUE)

model <- feols(bds_sr_hp ~ 1 | statefips + year | dln_wap_hp ~ l20_sh_under5_hp , data = df,
split = ~naics2)
etable(model)

plot <- coefplot(model)
ggsave("ivregs_coeffs.pdf", plot = plot$plot, width = 8, height = 6)

model2 <- feols(bds_sr_hp ~ dln_wap_hp | statefips + year, data = df,
split = ~naics2)
etable(model2)

plot <- coefplot(model2)
ggsave("feregs_coeffs.pdf", plot = plot$plot, width = 8, height = 6)