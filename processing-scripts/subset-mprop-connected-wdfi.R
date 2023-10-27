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
mprop.owners <- read_csv("data/mprop/Parcels_with_Ownership_Groups.csv") %>%
  group_by(OWNER_NAME_1) %>%
  summarise() %>%
  # match to WDFI records by name
  left_join(wdfi.current %>%
              select(corp_name_clean, wdfi_id, registered_agent, wdfi_address),
            by = c("OWNER_NAME_1" = "corp_name_clean"))

# WDFI registrations of landlords from the MPROP file
wdfi.mprop.matches <- wdfi.current %>%
  filter(corp_name_clean %in% mprop.owners$OWNER_NAME_1)

# these *current* WDFI records are matched to an MPROP owner name
wdfi.mprop.connected <- wdfi.current %>%
  filter(!is.na(wdfi_address),
         ! wdfi_address %in% wdfi.addresses.not.useful$wdfi_agent_address,
         corp_name_clean %in% mprop.owners$OWNER_NAME_1)
write_csv(wdfi.mprop.connected, "data/wdfi/wdfi-connected-to-mprop.csv")
