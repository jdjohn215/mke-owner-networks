rm(list = ls())

library(tidyverse)

# This script uses Milwaukee's Master Address Index (MAI) file to identify
#   every address corresponding to each TAXKEY

mai <- read_csv("https://data.milwaukee.gov/dataset/566af1a6-0499-4766-a89e-2f2a4b4d6e2d/resource/9f905487-720e-4f30-ae70-b5ec8a2a65a1/download/mai.csv")

taxkey.addresses <- mai |>
  unite("address_string", HSE_NBR, SFX, DIR, STREET, STTYPE, na.rm = T, sep = " ") |>
  group_by(TAXKEY) |>
  summarise(complete_addresses = paste(unique(address_string), collapse = "|"))

write_csv(taxkey.addresses, paste0("data/mai/taxkey-addresses_", Sys.Date(), ".csv"))
