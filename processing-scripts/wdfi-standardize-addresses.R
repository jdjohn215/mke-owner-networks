rm(list = ls())

library(tidyverse)
library(tidygeocoder)

wdfi <- read_csv("data/wdfi/wdfi-current-in-mprop.csv")
wdfi.addresses <- wdfi %>%
  select(entity_id, principal_office_raw, agent_raw) %>%
  pivot_longer(cols = -entity_id, values_to = "wdfi_address_raw")

# addresses previously standardized by geocodio
#   or standardization attempted and failed
standardized.addresses <- read_csv("data/wdfi/standardized-addresses.csv")

# new addresses
new.addresses <- wdfi.addresses %>%
  filter(! wdfi_address_raw %in% standardized.addresses$wdfi_address_raw) %>%
  group_by(wdfi_address_raw) %>%
  summarise()

if(nrow(new.addresses) > 0){
  # try geocoding new addresses
  new.addresses.geocodio <- geocode(.tbl = new.addresses,
                                    address = wdfi_address_raw,
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
                               NA_character_),
           zip2 = str_sub(address_components.zip, 1, 5)) %>%
    # create combined address string, dropping NA variables
    unite(col = "wdfi_address", address_components.number, address_components.street,
          address_components.suffix, unittype2, address_components.secondarynumber,
          city2, state2, address_components.zip,
          na.rm = T, remove = FALSE, sep = " ") %>%
    # replace standardized address w/original address as needed
    mutate(wdfi_address = str_replace_all(wdfi_address, " ,", ","),
           wdfi_address = case_when(
             accuracy < 0.9 ~ wdfi_address_raw,
             is.na(address_components.number) ~ wdfi_address_raw,
             is.na(address_components.city) ~ wdfi_address_raw,
             TRUE ~ str_to_upper(wdfi_address)
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
                                                select(wdfi_address, wdfi_address_raw, standardized))
} else {
  standardized.addresses.updated <- standardized.addresses
}

table(standardized.addresses.updated$standardized)

################################################################################
# final formatting
standardized.addresses.updated <- standardized.addresses.updated %>%
  mutate(wdfi_address = str_to_upper(wdfi_address),
         wdfi_address = str_replace_all(wdfi_address, "P[.]O[.]|P[.] O[.]|P[.]0[.]", "PO"),
         wdfi_address = str_replace_all(wdfi_address, "P[.]O ", "PO "),
         wdfi_address = str_replace_all(wdfi_address, "P O BOX", "PO BOX")) %>%
  # ensure that zip code is only 5-digits
  mutate(wdfi_address = if_else(
    condition = str_sub(word(wdfi_address, -1), 1, 1) %in% paste(1:5),
    true = paste(word(wdfi_address, 1, -2), str_sub(word(wdfi_address, -1), 1, 5)),
    false = wdfi_address
  ))

################################################################################
# add standardized addresses to wdfi
wdfi.with.standardized <- wdfi.addresses %>%
  inner_join(standardized.addresses.updated) %>%
  select(entity_id, name, address = wdfi_address, standardized) %>%
  mutate(name = str_remove(name, "_raw")) %>%
  pivot_wider(names_from = name, values_from = c(address, standardized),
              names_glue = "{name}_{.value}") %>%
  inner_join(wdfi)

################################################################################
# identify all the addresses used by useless registered agents
#   remove records where the PRINCIPAL OFFICE ADDRESS is the same as one of these
# wdfi useless registered agents
wdfi.agents.not.useful <- readxl::read_excel("data/munges/WDFI_notes.xlsx",
                                             sheet = 1) %>%
  mutate(registered_agent = str_replace_all(registered_agent, "\\s", " "))

# wdfi addresses used by useless registered agents
wdfi.addresses.not.useful <- wdfi.with.standardized %>%
  filter(registered_agent %in% wdfi.agents.not.useful$registered_agent |
           str_detect(registered_agent, "\\bLAW\\b|\\bLAWYERS\\b|\\bLAWYER\\b|\\bATTORNEY\\b|\\TAX\\b|\\bACCOUNTING\\b|\\bINCORPORATING\\b|\\bAGENT\\b|\\bAGENTS\\b|CORPORATE SERV")) %>%
  group_by(agent_address) %>%
  summarise()

# update MPROP useless addresses
read_csv("data/mprop/useless-addresses.csv") %>%
  rename(address = 1) %>%
  bind_rows(wdfi.addresses.not.useful %>% rename(address = 1)) %>%
  group_by(address) %>%
  summarise() %>%
  write_csv("data/mprop/useless-addresses.csv")

useful.wdfi.with.standardized <- wdfi.with.standardized %>%
  filter(! principal_office_address %in% wdfi.addresses.not.useful$agent_address)


write_csv(useful.wdfi.with.standardized, "data/wdfi/wdfi-current-in-mprop_StandardizedAddresses.csv")

# save updated table of standardized addresses
write_csv(standardized.addresses.updated, "data/wdfi/standardized-addresses.csv")
