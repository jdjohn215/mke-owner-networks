rm(list = ls())

library(tidyverse)

# This script uses Milwaukee's Master Address Index (MAI) file to identify
#   every address corresponding to each TAXKEY
#
# MAI is also used as the source for unit number to be able to distinguish properties like
# condominium units that may share the same address. MPROP includes the "house number suffix"
# field, but this is distinct from unit number. House number suffix is most commonly used when
# two properties share a house number, but one does have direct street frontage These get "ADJ"
# (adjacent) or "R" (rear) as a suffix.
#
# In some cases, a single taxkey can have multiple unit numbers (e.g. it is an apartment building).
# 2848 W WISCONSIN AVE is an example of this in the MAI data. We don't want to show a unit number
# in that case. We are only interested in showing unit numbers where it helps distinguish
# distinct properties that would otherwise have the same address.

mai <- read_csv("https://data.milwaukee.gov/dataset/566af1a6-0499-4766-a89e-2f2a4b4d6e2d/resource/9f905487-720e-4f30-ae70-b5ec8a2a65a1/download/mai.csv")

taxkey.addresses <- mai |>
  unite("address_string", HSE_NBR, SFX, DIR, STREET, STTYPE, na.rm = T, sep = " ", remove = FALSE) |>
  group_by(TAXKEY) |>
  summarise(
    UNIT_NBR = if (n_distinct(UNIT_NBR) == 1) first(UNIT_NBR) else NA_character_,
    complete_addresses = paste(unique(address_string), collapse = "|")
  )

write_csv(taxkey.addresses, paste0("data/mai/taxkey-addresses_", Sys.Date(), ".csv"), na = "")
