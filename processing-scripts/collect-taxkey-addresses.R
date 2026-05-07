rm(list = ls())

library(tidyverse)

# This script uses Milwaukee's Master Address Index (MAI) file to identify
#   every address corresponding to each TAXKEY

mai <- read_csv("https://data.milwaukee.gov/dataset/566af1a6-0499-4766-a89e-2f2a4b4d6e2d/resource/9f905487-720e-4f30-ae70-b5ec8a2a65a1/download/mai.csv")

taxkey.addresses <- mai |>
  unite("address_string", HSE_NBR, SFX, DIR, STREET, STTYPE, na.rm = T, sep = " ", remove = FALSE) |>
  group_by(TAXKEY) |>
  summarise(
    UNIT_NBR = if (n_distinct(UNIT_NBR) == 1) first(UNIT_NBR) else NA_character_,
    complete_addresses = paste(unique(address_string), collapse = "|")
  )

write_csv(taxkey.addresses, paste0("data/mai/taxkey-addresses_", Sys.Date(), ".csv"), na = "")
