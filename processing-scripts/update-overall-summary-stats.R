rm(list = ls())

library(tidyverse)

df <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")
updated <- read_csv("data/process-dates-updated.csv")

network.totals <- df %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = n_distinct(mprop_name)) %>%
  ungroup()

overall.totals <- network.totals %>%
  summarise(total_parcels = sum(parcels),
            total_units = sum(units),
            total_networks = n(),
            networks_single_parcel = sum(parcels == 1),
            pct_networks_single_parcel = networks_single_parcel/total_networks*100,
            networks_multiple_parcels = sum(parcels > 1),
            pct_networks_multiple_parcels = networks_multiple_parcels/total_networks*100,
            networks_multiple_names = sum(names > 1),
            pct_networks_multiple_names = networks_multiple_names/total_networks*100,
            parcels_single_parcel_owner = sum(parcels[parcels == 1]),
            pct_parcels_single_parcel_owner = parcels_single_parcel_owner/total_parcels*100,
            parcels_multiple_parcel_owner = sum(parcels[parcels > 1]),
            parcels_multiple_name_owner = sum(parcels[names > 1]),
            pct_parcels_multiple_name_owner = parcels_multiple_name_owner/total_parcels*100) %>%
  mutate(total_mprop_names = n_distinct(df$mprop_name),
         total_mprop_addresses = n_distinct(df$mprop_address))

overall.totals.long <- overall.totals %>%
  pivot_longer(cols = everything()) %>%
  mutate(value = if_else(str_detect(name, "pct"),
                         true = paste0(round(value), "%"),
                         false = prettyNum(value, big.mark = ","))) %>%
  bind_rows(
    tibble(name = c("mprop_updated", "wdfi_updated", "workflow_updated"),
           value = format.Date(c(updated$mprop, updated$wdfi, updated$workflow),
                               format = "%b %d, %Y"))
  )

write_csv(overall.totals.long, "data/overall-summary-stats.csv")
