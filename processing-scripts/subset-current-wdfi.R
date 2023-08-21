rm(list = ls())

library(tidyverse)

# the original WDFI file
wdfi.orig <- vroom::vroom("data/wdfi/WDFI_2023-07-03.csv.gz")

# these entities are currently incorporated
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- wdfi.orig %>%
  filter(current_status %in% c("ORG", "IGS", "DLQ", "INC", "RGD", "IBS", "RLT"))

clean.names <- wdfi.current %>%
  # apply same cleaning routine as applied to OWNER_NAME_1
  mutate(corp_name_clean = str_remove_all(corp_name, ","),
         corp_name_clean = str_remove_all(corp_name_clean, coll(".")),
         corp_name_clean = str_remove_all(corp_name_clean, "#"),
         corp_name_clean = str_replace(corp_name_clean, " - ", "-"),
         corp_name_clean = str_squish(corp_name_clean),
         corp_name_clean = str_replace(corp_name_clean, "\\bLL$", "LLC"),
         registered_agent = str_squish(str_to_upper(str_remove_all(registered_agent, "[.]|[,]"))))


fix.addresses <- clean.names %>%
  select(wdfi_id, address_line1, address_line2, city) %>%
  # sometimes address_line2 includes long content that should've been in line1
  #   add it to line1 if applicable and standardize the string
  mutate(address_line1 = str_squish(str_to_upper(str_remove_all(address_line1, "[.]|[,]"))),
         address_line2 = str_squish(str_to_upper(str_remove_all(address_line2, "[.]"))),
         address_line3 = case_when(
           is.na(address_line2) ~ address_line1,
           str_detect(address_line2, "[,]") ~ paste(address_line1, word(address_line2, 1, sep = ","), sep = ", "),
           TRUE ~ address_line1
         )) %>%
  # some standardizations, especially of street suffixes
  mutate(address_line3 = str_remove_all(address_line3, coll(".")),
         address_line3 = str_remove_all(address_line3, "#"),
         address_line3 = str_replace(address_line3, "\\bSTE\\b", "SUITE"),
         address_line3 = str_replace(address_line3, " - ", "-"),
         address_line3 = str_replace(address_line3, "\\bAVENUE\\b|\\bAVE\\b", "AV"),
         address_line3 = str_replace(address_line3, "\\bLANE\\b|\\bLN\\b", "LA"),
         address_line3 = str_replace(address_line3, "\\bROAD\\b", "RD"),
         address_line3 = str_replace(address_line3, "\\bBOULEVARD\\b|\\bBLVD\\b", "BL"),
         address_line3 = str_replace(address_line3, "\\bCOURT\\b", "CT"),
         address_line3 = str_replace(address_line3, "\\bSTREET\\b", "ST"),
         address_line3 = str_replace(address_line3, "\\bPARKWAY\\b|\\bPKWY\\b", "PK"),
         address_line3 = str_replace(address_line3, "\\bTERRACE\\b", "TR"),
         address_line3 = str_replace(address_line3, "\\bWAY\\b", "WA"),
         address_line3 = str_replace(address_line3, "\\bDRIVE\\b", "DR"),
         address_line3 = str_replace(address_line3, "\\bCIRCLE\\b|\\bCIR\\b", "CR"))


fix.addresses2 <- fix.addresses %>%
  # extract a value from address_line2 if applicable
  #   if an alphabetical value or a number is present just pull that value
  #   if LOWER or UPPER is present, use that
  mutate(address_line2 = word(address_line2, -1, sep = ",")) %>%
  mutate(unit = case_when(
    is.na(address_line2) ~ NA_character_,
    str_detect(address_line2, "\\bUPP") ~ "UPPER",
    str_detect(address_line2, "\\bLOW") ~ "LOWER",
    str_detect(address_line2, paste0("\\b", LETTERS, "\\b", collapse = "|")) ~ str_match(address_line2, paste0("\\b", LETTERS, "\\b", collapse = "|"))[,1],
    str_detect(address_line2, "[0-9]") ~ as.character(parse_number(address_line2)),
    TRUE ~ address_line2)) %>%
  mutate(address_city = if_else(condition = is.na(unit),
                                true = paste(address_line3, city, sep = ", "),
                                false = paste(address_line3, unit, city, sep = ", ")))


# current WDFI with cleaned and combined address field
wdfi.final.current <- clean.names %>%
  inner_join(fix.addresses2 %>%
               select(wdfi_id, address_city))
write_csv(wdfi.final.current, "data/wdfi/WDFI_Current_2023-07-03.csv.gz")
