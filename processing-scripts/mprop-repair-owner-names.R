rm(list = ls())

library(tidyverse)

# this script repairs corporate owner names by matching them to their correct WDFI value

################################################################################
# clean, landlord-owned parcel data
mprop <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses.csv")

# owner names from mprop
mprop.names <- mprop %>% group_by(mprop_name) %>% summarise()

################################################################################
# the original WDFI file
wdfi.current <- vroom::vroom("data/wdfi/WDFI_PrincipalAddress_Current.csv.gz")

# corporate names
wdfi.names <- wdfi.current %>% 
  select(entity_id, corp_name_clean) %>%
  mutate(corp_name_no_punc = str_remove_all(corp_name_clean, "[[:punct:] ]+"))


################################################################################
# mprop names not appearing in WDFI
not.in.wdfi <- mprop.names %>% filter(! mprop_name %in% wdfi.names$corp_name_clean)

# find WDFI name match in 1 of two ways:
#   - try appending "LLC" to the end of the owner name string
#   - try matching the mprop name to the WDFI name after removing *all* punctuation and spaces from both
name.repairs <- not.in.wdfi %>%
  mutate(add_llc = paste(mprop_name, "LLC"),
         remove_punc = str_remove_all(mprop_name, "[[:punct:] ]+")) %>%
  left_join(wdfi.names, by = c("add_llc" = "corp_name_clean")) %>%
  left_join(wdfi.names, by = c("remove_punc" = "corp_name_no_punc")) %>%
  mutate(entity_id = if_else(is.na(entity_id.x), entity_id.y, entity_id.x)) %>%
  select(mprop_name, entity_id) %>%
  inner_join(wdfi.names %>% select(entity_id, corp_name_clean)) %>%
  filter(!is.na(entity_id)) %>%
  # remove any multiple matches, if necessary (shouldn't be)
  group_by(mprop_name) %>%
  filter(n() == 1) %>%
  ungroup()
name.repairs

################################################################################
mprop.repaired <- mprop %>%
  left_join(name.repairs) %>%
  mutate(mprop_name = if_else(!is.na(corp_name_clean), corp_name_clean, mprop_name)) %>%
  select(-c(corp_name_clean, entity_id))

write_csv(mprop.repaired, "data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses_RepairedNames.csv")
