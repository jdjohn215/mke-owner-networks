rm(list = ls())

library(tidyverse)
library(tidygeocoder)

mprop <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied.csv")

# addresses previously standardized by geocodio
#   or standardization attempted and failed
standardized.addresses <- read_csv("data/mprop/standardized-addresses.csv")

# new addresses
new.addresses <- mprop %>%
  filter(! mprop_address_raw %in% standardized.addresses$mprop_address_raw) %>%
  group_by(mprop_address_raw) %>%
  summarise()

if(nrow(new.addresses) > 0){
  # try geocoding new addresses
  new.addresses.geocodio <- geocode(.tbl = new.addresses,
                                    address = mprop_address_raw,
                                    full_results = TRUE,
                                    method = "geocodio")
  
  # process geocoded addresses, creating standardized full address where
  #   validation was successful
  new.addresses.standardized <- new.addresses.geocodio %>%
    # ensure all columns are present by adding NA columns if missing
    bind_rows(tibble(address_components.number = character(),
                     address_components.street = character(), 
                     address_components.suffix = character(),
                     address_components.secondaryunit = character(), 
                     address_components.secondarynumber = character(),
                     address_components.city = character(), 
                     address_components.state = character())) %>%
    # add commas where relevant
    mutate(city2 = paste(",", address_components.city),
           state2 = paste(",", address_components.state),
           unittype2 = if_else(!is.na(address_components.secondaryunit), 
                               paste(",", address_components.secondaryunit), 
                               NA_character_)) %>%
    # create combined address string, dropping NA variables
    unite(col = "mprop_address", address_components.number, address_components.street,
          address_components.suffix, unittype2, address_components.secondarynumber,
          city2, state2, address_components.zip,
          na.rm = T, remove = FALSE, sep = " ") %>%
    # replace standardized address w/original address as needed
    mutate(mprop_address = str_replace_all(mprop_address, " ,", ","),
           mprop_address = case_when(
             accuracy < 0.9 ~ mprop_address_raw,
             is.na(address_components.number) ~ mprop_address_raw,
             is.na(address_components.city) ~ mprop_address_raw,
             TRUE ~ str_to_upper(mprop_address)
           ),
           standardized = case_when(
             accuracy < 0.9 ~ FALSE,
             is.na(address_components.number) ~ FALSE,
             is.na(address_components.city) ~ FALSE,
             TRUE ~ TRUE
           ))
  
  
  # add new standardized addresses
  standardized.addresses.updated <- bind_rows(standardized.addresses, 
                                              new.addresses.standardized %>%
                                                select(mprop_address, mprop_address_raw, standardized)) %>%
    mutate(mprop_address = str_replace_all(mprop_address, "P O BOX", "PO BOX"))
} else {
  standardized.addresses.updated <- standardized.addresses %>%
    mutate(mprop_address = str_replace_all(mprop_address, "P O BOX", "PO BOX"))
}


table(standardized.addresses.updated$standardized)

# add standardized addresses to mprop
mprop.with.standardized <- mprop %>%
  left_join(standardized.addresses.updated)
write_csv(mprop.with.standardized, "data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses.csv")

# save updated table of standardized addresses
write_csv(standardized.addresses.updated, "data/mprop/standardized-addresses.csv")

