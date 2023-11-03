rm(list = ls())

library(tidyverse)

# the current WDFI file
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- vroom::vroom("data/wdfi/WDFI_Current_2023-10-09.csv.gz") %>%
  mutate(wdfi_address = str_to_upper(str_squish(str_remove_all(wdfi_address, pattern = coll(",")))),
         wdfi_agent_address = str_to_upper(str_squish(str_remove_all(wdfi_agent_address, pattern = coll(",")))))

# wdfi useless registered agents
wdfi.agents.not.useful <- readxl::read_excel("data/munges/WDFI_notes.xlsx",
                                             sheet = 1) %>%
  mutate(registered_agent = str_replace_all(registered_agent, "\\s", " "))

# wdfi addresses used by useless registered agents
wdfi.addresses.not.useful <- wdfi.current %>%
  filter(registered_agent %in% wdfi.agents.not.useful$registered_agent |
           str_detect(registered_agent, "\\bLAW\\b|\\bLAWYERS\\b|\\bLAWYER\\b|\\bATTORNEY\\b|\\TAX\\b|\\bACCOUNTING\\b|\\bINCORPORATING\\b|\\bAGENT\\b|\\bAGENTS\\b|CORPORATE SERV")) %>%
  group_by(wdfi_agent_address) %>%
  summarise()


# all the MPROP landlords
mprop.owners <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses.csv") %>%
  group_by(mprop_name) %>%
  summarise() %>%
  # match to WDFI records by name
  left_join(wdfi.current %>%
              select(corp_name_clean, wdfi_id, registered_agent, wdfi_address),
            by = c("mprop_name" = "corp_name_clean"))

# WDFI registrations of landlords from the MPROP file
wdfi.mprop.matches <- wdfi.current %>%
  filter(corp_name_clean %in% mprop.owners$mprop_name)

# these *current* WDFI records are matched to an MPROP owner name
wdfi.mprop.connected <- wdfi.current %>%
  filter(!is.na(wdfi_address),
         ! wdfi_address %in% wdfi.addresses.not.useful$wdfi_agent_address,
         corp_name_clean %in% mprop.owners$mprop_name)
write_csv(wdfi.mprop.connected, "data/wdfi/wdfi-connected-to-mprop.csv")

n_distinct(wdfi.mprop.connected$wdfi_address)
n_distinct(wdfi.mprop.connected$principal_address_raw)
wdfi.mprop.connected %>%
  group_by(principal_address_raw) %>%
  summarise() %>%
  write_csv("~/downloads/unique-principal-addresses.csv")

geocodio <- read_csv("~/downloads/unique-principal-addresses_geocodio.csv") %>%
  # add commas where relevant
  mutate(city2 = paste(",", City),
         state2 = paste(",", State),
         unittype2 = if_else(!is.na(`Unit Type`), paste(",", `Unit Type`), NA_character_)) %>%
  # create combined address string, dropping NA variables
  unite(col = "principal_address", Number, Street, unittype2, `Unit Number`, city2, state2, Zip,
        na.rm = T, remove = FALSE, sep = " ") %>%
  # replace standardized address w/original address as needed
  mutate(principal_address = str_replace_all(principal_address, " ,", ","),
         principal_address = case_when(
           `Accuracy Score` < 0.9 ~ principal_address_raw,
           is.na(Number) ~ principal_address_raw,
           is.na(City) ~ principal_address_raw,
           TRUE ~ str_to_upper(principal_address)
         ))

n_distinct(geocodio$principal_address_raw)
n_distinct(geocodio$principal_address)
