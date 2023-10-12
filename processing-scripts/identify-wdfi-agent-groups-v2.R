rm(list = ls())

library(tidyverse)

# the current WDFI file
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- vroom::vroom("data/wdfi/WDFI_Current_2023-10-09.csv.gz") %>%
  mutate(address_city = str_to_upper(str_squish(str_remove_all(address_city, pattern = coll(",")))),
         address_city_agent = str_to_upper(str_squish(str_remove_all(address_city_agent, pattern = coll(",")))))

# wdfi useless registered agents
wdfi.agents.not.useful <- readxl::read_excel("data/munges/WDFI_notes.xlsx",
                                      sheet = 1) %>%
  mutate(registered_agent = str_replace_all(registered_agent, "\\s", " "))

# wdfi addresses used by useless registered agents
wdfi.addresses.not.useful <- wdfi.current %>%
  filter(registered_agent %in% wdfi.agents.not.useful$registered_agent |
           str_detect(registered_agent, "\\bLAW\\b|\\bLAWYERS\\b|\\bLAWYER\\b|\\bATTORNEY\\b|\\TAX\\b|\\bACCOUNTING\\b|\\bINCORPORATING\\b|\\bAGENT\\b|\\bAGENTS\\b|CORPORATE SERV")) %>%
  group_by(address_city_agent) %>%
  summarise()


# all the MPROP landlords
mprop.owners <- read_csv("data/mprop/Parcels_with_Ownership_Groups.csv") %>%
  group_by(OWNER_NAME_1) %>%
  summarise() %>%
  # match to WDFI records by name
  left_join(wdfi.current %>%
              select(corp_name_clean, wdfi_id, registered_agent, address_city),
            by = c("OWNER_NAME_1" = "corp_name_clean"))

# WDFI registrations of landlords from the MPROP file
wdfi.mprop.matches <- wdfi.current %>%
  filter(corp_name_clean %in% mprop.owners$OWNER_NAME_1)

# these *current* WDFI records are matched to an MPROP owner name
wdfi.mprop.connected <- wdfi.current %>%
  filter(!is.na(address_city),
         ! address_city %in% wdfi.addresses.not.useful$address_city_agent,
         corp_name_clean %in% mprop.owners$OWNER_NAME_1) %>%
  # corp_names must be unique per WI law. Sometimes a corp has multiple entries, 
  #   apparently due to reorganization. This code just keeps the entry with the
  #   most recent status update
  group_by(corp_name_clean) %>%
  filter(row_number() == 1) %>%
  ungroup() %>%
  select(wdfi_id, address_city)

wdfi.networks <- wdfi.mprop.connected %>%
  arrange(address_city) %>%
  group_by(address_city) %>%
  mutate(wdfi_group_row = row_number()) %>%
  ungroup() %>%
  mutate(wdfi_group_id = cumsum(wdfi_group_row == 1)) %>%
  select(wdfi_id, address_city, wdfi_group_id)

wdfi.networks.total <- wdfi.networks %>%
  group_by(address_city, wdfi_group_id) %>%
  summarise(wdfi_ids = paste(wdfi_id, collapse = ","),
            unique_ids = n())

wdfi.networks

all.wdfi.groups.final <- wdfi.current %>%
  select(wdfi_id, corp_name_clean, address_city) %>%
  inner_join(wdfi.networks)
write_csv(all.wdfi.groups.final, "data/wdfi/wdfi_agent_groups-v2.csv")
