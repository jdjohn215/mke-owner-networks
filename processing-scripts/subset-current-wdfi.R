rm(list = ls())

library(tidyverse)

# the original WDFI file
wdfi.orig <- vroom::vroom("data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz") %>%
  janitor::clean_names() %>%
  mutate(across(.cols = where(is.character),
                .fns = ~if_else(.x %in% c("NULL", "XX"), NA, .x)))

clean.names <- wdfi.orig %>%
  # apply same cleaning routine as applied to OWNER_NAME_1
  mutate(corp_name_clean = str_remove_all(entity_name, ","),
         corp_name_clean = str_remove_all(corp_name_clean, coll(".")),
         corp_name_clean = str_remove_all(corp_name_clean, "#"),
         corp_name_clean = str_replace(corp_name_clean, " - ", "-"),
         corp_name_clean = str_squish(corp_name_clean),
         corp_name_clean = str_replace(corp_name_clean, "\\bLL$", "LLC"),
         registered_agent = str_squish(str_to_upper(str_remove_all(agent_name, "[.]|[,]"))))

# these entities are currently incorporated
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- clean.names %>%
  filter(entity_status %in% c("ORG", "IGS", "DLQ", "INC", "RGD", "IBS", "RLT")) %>%
  # a small number of the cleaned names have duplicates
  #   corporation names are required to be unique
  #   this keeps just the most recently incorporated of the two identically-named companies
  group_by(entity_id) %>%
  filter(row_number() == 1) %>%
  ungroup() %>%
  group_by(corp_name_clean) %>%
  slice_max(order_by = incorporated_date, n = 1, with_ties = FALSE) %>%
  ungroup()

################################################################################
# all the MPROP landlords
mprop.owners.in.wdfi <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses.csv") %>%
  group_by(mprop_name) %>%
  summarise() %>%
  # match to WDFI records by name
  inner_join(wdfi.current %>%
               select(corp_name_clean, entity_id),
             by = c("mprop_name" = "corp_name_clean"))

# create raw address strings for principal office and agent
wdfi.current.in.mprop <- wdfi.current %>%
  filter(entity_id %in% mprop.owners.in.wdfi$entity_id) %>%
  # add commas where relevant
  mutate(city2 = if_else(!is.na(principal_office_city),
                         paste(",", principal_office_city),
                         NA_character_),
         state2 = if_else(!is.na(principal_office_state),
                          paste(",", principal_office_state),
                          NA_character_),
         add2 = if_else(!is.na(principal_office_add2),
                        paste(",", principal_office_add2),
                        NA_character_)) %>%
  unite(col = "principal_office_raw", 
        principal_office_add1, add2, city2, state2, principal_office_zip,
        remove = FALSE, sep = " ", na.rm = T) %>%
  # add commas where relevant
  mutate(city2 = if_else(!is.na(agent_city),
                         paste(",", agent_city),
                         NA_character_),
         state2 = if_else(!is.na(agent_state),
                          paste(",", agent_state),
                          NA_character_),
         add2 = if_else(!is.na(agent_add2),
                        paste(",", agent_add2),
                        NA_character_)) %>%
  unite(col = "agent_raw", 
        agent_add1, add2, city2, state2, agent_zip,
        remove = FALSE, sep = " ", na.rm = T) %>%
  mutate(across(.cols = contains("raw"), .fns = ~str_replace_all(.x, " ,", ",")),
         across(.cols = where(is.character), .fns = ~na_if(.x, ""))) %>%
  select(-c(city2, state2, add2)) %>%
  # remove those missing a principal office address
  filter(!is.na(principal_office_raw))
write_csv(wdfi.current.in.mprop, "data/wdfi/wdfi-current-in-mprop.csv")
