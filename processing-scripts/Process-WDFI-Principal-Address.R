rm(list = ls())

library(tidyverse)

wdfi.orig <- vroom::vroom("data/wdfi/Marquette Corp Database 02132025.txt",
                          col_names = c("EntityID", "EntityName", "EntityStatus", "EntityType", "Incorporated Date", 
                                        "AgentName", "AgentAdd1", "AgentAdd2", "AgentCity", "AgentState", 
                                        "AgentZIP", "AgentCountry", "PrincipalOfficeAdd1", "PrincipalOfficeAdd2", 
                                        "PrincipalOfficeCity", "PrincipalOfficeState", "PrincipalOfficeZIP", 
                                        "PrincipalOfficeCountry"))

################################################################################
# subset CURRENT WDFI
wdfi.processed <- wdfi.orig %>%
  janitor::clean_names() %>%
  mutate(across(.cols = where(is.character),
                .fns = ~if_else(.x %in% c("NULL", "XX"), NA, .x)))

clean.names <- wdfi.processed %>%
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

write_csv(wdfi.current, "data/wdfi/WDFI_PrincipalAddress_Current.csv.gz")
