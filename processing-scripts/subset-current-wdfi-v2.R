rm(list = ls())

library(tidyverse)

# the original WDFI file
wdfi.orig <- vroom::vroom("data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz") %>%
  janitor::clean_names() %>%
  mutate(agent_name = if_else(agent_name == "NULL", NA_character_, agent_name),
         agent_add1 = if_else(agent_add1 == "NULL", NA_character_, agent_add1),
         agent_add2 = if_else(agent_add2 == "NULL", NA_character_, agent_add2),
         principal_office_add1 = if_else(principal_office_add1 == "NULL", NA_character_, principal_office_add1),
         principal_office_add2 = if_else(principal_office_add2 == "NULL", NA_character_, principal_office_add2),
         principal_office_city = if_else(principal_office_city == "NULL", NA_character_, principal_office_city),
         principal_office_state = if_else(principal_office_state == "NULL", NA_character_, principal_office_state),
         principal_office_zip = if_else(principal_office_zip == "NULL", NA_character_, principal_office_zip),
         principal_office_country = if_else(principal_office_country == "NULL", NA_character_, principal_office_country))

# these entities are currently incorporated
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- wdfi.orig %>%
  filter(entity_status %in% c("ORG", "IGS", "DLQ", "INC", "RGD", "IBS", "RLT")) %>%
  group_by(entity_id) %>%
  filter(row_number() == 1) %>%
  ungroup()

clean.names <- wdfi.current %>%
  # apply same cleaning routine as applied to OWNER_NAME_1
  mutate(corp_name_clean = str_remove_all(entity_name, ","),
         corp_name_clean = str_remove_all(corp_name_clean, coll(".")),
         corp_name_clean = str_remove_all(corp_name_clean, "#"),
         corp_name_clean = str_replace(corp_name_clean, " - ", "-"),
         corp_name_clean = str_squish(corp_name_clean),
         corp_name_clean = str_replace(corp_name_clean, "\\bLL$", "LLC"),
         registered_agent = str_squish(str_to_upper(str_remove_all(agent_name, "[.]|[,]"))))


fix.addresses <- clean.names %>%
  select(wdfi_id = entity_id, principal_office_add1, principal_office_add2, principal_office_city,
         agent_add1, agent_add2, agent_city) %>%
  # sometimes address_line2 includes long content that should've been in line1
  #   add it to line1 if applicable and standardize the string
  mutate(address_line1_principal = str_squish(str_to_upper(str_remove_all(principal_office_add1, "[.]|[,]"))),
         address_line2_principal = str_squish(str_to_upper(str_remove_all(principal_office_add2, "[.]"))),
         address_line3_principal = case_when(
           is.na(address_line2_principal) ~ address_line1_principal,
           str_detect(address_line2_principal, "[,]") ~ paste(address_line1_principal, 
                                                              word(address_line2_principal, 1, sep = ","), 
                                                              sep = ", "),
           TRUE ~ address_line1_principal
         )) %>%
  # some standardizations, especially of street suffixes
  mutate(address_line3_principal = str_remove_all(address_line3_principal, coll(".")),
         address_line3_principal = str_remove_all(address_line3_principal, "#"),
         address_line3_principal = str_replace(address_line3_principal, "\\bSTE\\b", "SUITE"),
         address_line3_principal = str_replace(address_line3_principal, " - ", "-"),
         address_line3_principal = str_replace(address_line3_principal, "\\bAVENUE\\b|\\bAVE\\b", "AV"),
         address_line3_principal = str_replace(address_line3_principal, "\\bLANE\\b|\\bLN\\b", "LA"),
         address_line3_principal = str_replace(address_line3_principal, "\\bROAD\\b", "RD"),
         address_line3_principal = str_replace(address_line3_principal, "\\bBOULEVARD\\b|\\bBLVD\\b", "BL"),
         address_line3_principal = str_replace(address_line3_principal, "\\bCOURT\\b", "CT"),
         address_line3_principal = str_replace(address_line3_principal, "\\bSTREET\\b", "ST"),
         address_line3_principal = str_replace(address_line3_principal, "\\bPARKWAY\\b|\\bPKWY\\b", "PK"),
         address_line3_principal = str_replace(address_line3_principal, "\\bTERRACE\\b", "TR"),
         address_line3_principal = str_replace(address_line3_principal, "\\bWAY\\b", "WA"),
         address_line3_principal = str_replace(address_line3_principal, "\\bDRIVE\\b", "DR"),
         address_line3_principal = str_replace(address_line3_principal, "\\bCIRCLE\\b|\\bCIR\\b", "CR")) %>%
  # sometimes address_line2 includes long content that should've been in line1
  #   add it to line1 if applicable and standardize the string
  mutate(address_line1_agent = str_squish(str_to_upper(str_remove_all(agent_add1, "[.]|[,]"))),
         address_line2_agent = str_squish(str_to_upper(str_remove_all(agent_add2, "[.]"))),
         address_line3_agent = case_when(
           is.na(address_line2_agent) ~ address_line1_agent,
           str_detect(address_line2_agent, "[,]") ~ paste(address_line1_agent, 
                                                              word(address_line2_agent, 1, sep = ","), 
                                                              sep = ", "),
           TRUE ~ address_line1_agent
         )) %>%
  # some standardizations, especially of street suffixes
  mutate(address_line3_agent = str_remove_all(address_line3_agent, coll(".")),
         address_line3_agent = str_remove_all(address_line3_agent, "#"),
         address_line3_agent = str_replace(address_line3_agent, "\\bSTE\\b", "SUITE"),
         address_line3_agent = str_replace(address_line3_agent, " - ", "-"),
         address_line3_agent = str_replace(address_line3_agent, "\\bAVENUE\\b|\\bAVE\\b", "AV"),
         address_line3_agent = str_replace(address_line3_agent, "\\bLANE\\b|\\bLN\\b", "LA"),
         address_line3_agent = str_replace(address_line3_agent, "\\bROAD\\b", "RD"),
         address_line3_agent = str_replace(address_line3_agent, "\\bBOULEVARD\\b|\\bBLVD\\b", "BL"),
         address_line3_agent = str_replace(address_line3_agent, "\\bCOURT\\b", "CT"),
         address_line3_agent = str_replace(address_line3_agent, "\\bSTREET\\b", "ST"),
         address_line3_agent = str_replace(address_line3_agent, "\\bPARKWAY\\b|\\bPKWY\\b", "PK"),
         address_line3_agent = str_replace(address_line3_agent, "\\bTERRACE\\b", "TR"),
         address_line3_agent = str_replace(address_line3_agent, "\\bWAY\\b", "WA"),
         address_line3_agent = str_replace(address_line3_agent, "\\bDRIVE\\b", "DR"),
         address_line3_agent = str_replace(address_line3_agent, "\\bCIRCLE\\b|\\bCIR\\b", "CR"))

fix.addresses2 <- fix.addresses %>%
  # extract a value from address_line2 if applicable
  #   if an alphabetical value or a number is present just pull that value
  #   if LOWER or UPPER is present, use that
  mutate(address_line2_principal = str_replace(address_line2_principal, "\\bP O\\b", "PO"),
         address_line2_principal = word(address_line2_principal, -1, sep = ","),
         address_line2_agent = str_replace(address_line2_agent, "\\bP O\\b", "PO"),
         address_line2_agent = word(address_line2_agent, -1, sep = ",")) %>%
  mutate(unit_principal = case_when(
    is.na(address_line2_principal) ~ NA_character_,
    str_detect(address_line2_principal, "\\bUPP") ~ "UPPER",
    str_detect(address_line2_principal, "\\bLOW") ~ "LOWER",
    str_detect(address_line2_principal, paste0("\\b", LETTERS, "\\b", collapse = "|")) ~ str_match(address_line2_principal, paste0("\\b", LETTERS, "\\b", collapse = "|"))[,1],
    str_detect(address_line2_principal, "[0-9]") ~ as.character(parse_number(address_line2_principal)),
    TRUE ~ address_line2_principal)) %>%
  mutate(unit_agent = case_when(
    is.na(address_line2_agent) ~ NA_character_,
    str_detect(address_line2_agent, "\\bUPP") ~ "UPPER",
    str_detect(address_line2_agent, "\\bLOW") ~ "LOWER",
    str_detect(address_line2_agent, paste0("\\b", LETTERS, "\\b", collapse = "|")) ~ str_match(address_line2_agent, paste0("\\b", LETTERS, "\\b", collapse = "|"))[,1],
    str_detect(address_line2_agent, "[0-9]") ~ as.character(parse_number(address_line2_agent)),
    TRUE ~ address_line2_agent)) %>%
  mutate(address_city = if_else(condition = is.na(unit_principal),
                                true = paste(address_line3_principal, principal_office_city, sep = ", "),
                                false = paste(address_line3_principal, unit_principal, principal_office_city, sep = ", ")),
         address_city = if_else(address_city == "NA, NA", NA_character_, address_city)) %>%
  mutate(address_city_agent = if_else(condition = is.na(unit_agent),
                                true = paste(address_line3_agent, agent_city, sep = ", "),
                                false = paste(address_line3_agent, unit_agent, agent_city, sep = ", ")),
         address_city_agent = if_else(address_city_agent == "NA, NA", NA_character_, address_city_agent))


# current WDFI with cleaned and combined address field
wdfi.final.current <- clean.names %>%
  rename(wdfi_id = entity_id) %>%
  inner_join(fix.addresses2 %>%
               select(wdfi_id, address_city, address_city_agent))
write_csv(wdfi.final.current, "data/wdfi/WDFI_Current_2023-10-09.csv.gz")
