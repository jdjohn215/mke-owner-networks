library(tidyverse)

# download the latest MPROP from the city's data portal
mprop.orig <- read_csv("https://data.milwaukee.gov/dataset/562ab824-48a5-42cd-b714-87e205e489ba/resource/0a2c7f31-cd15-4151-8222-09dd57d5f16d/download/mprop.csv")

# some transformations
mprop <- mprop.orig %>%
  # construct custom owner-occupied variables
  mutate(owner_occupied = case_when(
    # owner-occupied if MPROP variable says so
    !is.na(OWN_OCPD) ~ "owner occupied",
    # cannot be owner occupied if zip codes don't match
    str_sub(OWNER_ZIP, 1, 5) != str_sub(GEO_ZIP_CODE, 1, 5) ~ "not owner occupied",
    # cannot be owner occupied if mailing address is PO BOX
    str_detect(string = str_remove_all(OWNER_MAIL_ADDR, "[.]"),
               pattern = "\\bPO BOX\\b|\\bPO BOX\\b|\\bPOB\\b|\\bP O BOX\\b") ~ "not owner occupied",
    # cannot be owner occupied if not a house or condo
    ! C_A_CLASS %in% c(1, 5) ~ "not owner occupied",
    # is owner occupied if house numbers match
    suppressWarnings(parse_number(word(OWNER_MAIL_ADDR, 1, 1))) == HOUSE_NR_LO |
      suppressWarnings(parse_number(word(OWNER_MAIL_ADDR, 1, 1))) == HOUSE_NR_HI ~ "owner occupied",
    TRUE ~ "not owner occupied"
  )) %>%
  # subset columns
  select(TAXKEY, HOUSE_NR_LO, HOUSE_NR_HI, HOUSE_NR_SFX, SDIR, STREET, STTYPE,
         C_A_CLASS, LAND_USE_GP, C_A_TOTAL, NR_UNITS, OWNER_NAME_1,
         OWNER_NAME_2, OWNER_NAME_3, OWNER_MAIL_ADDR, OWNER_CITY_STATE, OWNER_ZIP, GEO_ZIP_CODE,
         owner_occupied, OWN_OCPD, GEO_ALDER) %>%
  # add text labels
  mutate(
    C_A_CLASS = case_when(
      C_A_CLASS == 1 ~ "Residential",
      C_A_CLASS == 2 ~ "Mercantile",
      C_A_CLASS == 3 ~ "Manufacturing",
      C_A_CLASS == 4 ~ "Special Mercantile",
      C_A_CLASS == 5 ~ "Condominiums",
      C_A_CLASS == 7 ~ "Mercantile Apts",
      C_A_CLASS == 9 ~ "Exempt",
      TRUE ~ as.character(C_A_CLASS)),
    LAND_USE_GP = case_when(
      LAND_USE_GP == 0 ~ "unclassifiable",
      LAND_USE_GP == 1 ~ "single family",
      LAND_USE_GP == 2 ~ "duplex",
      LAND_USE_GP == 3 ~ "multi-family",
      LAND_USE_GP == 4 ~ "mixed commercial/residential",
      LAND_USE_GP == 5 ~ "wholesale & retail trade",
      LAND_USE_GP == 6 ~ "Services, Finance, Insurance & Real Estate",
      LAND_USE_GP == 7 ~ "Mixed commercial",
      LAND_USE_GP == 8 ~ "Manufacturing, construction & warehousing",
      LAND_USE_GP == 9 ~ "Transportation",
      LAND_USE_GP == 10 ~ "Agriculture & fishing",
      LAND_USE_GP == 11 ~ "Public Schools & Buildings, Churches, Cemeteries, Quasi-Public Buildings",
      LAND_USE_GP == 12 ~ "Public Parks, Quasi-Public Open Space",
      LAND_USE_GP == 13 ~ "Vacant Land",
      TRUE ~ as.character(LAND_USE_GP)),
    across(where(is.character), str_to_upper),
    across(where(is.character), str_squish))

# residentially-zoned parcels, with more than 0 units, not owner-occupied
residential.landlord <- mprop %>%
  filter(C_A_CLASS %in% c("RESIDENTIAL", "CONDOMINIUMS", "MERCANTILE APTS") |
           LAND_USE_GP == "mixed commercial/residential",
         NR_UNITS > 0,
         owner_occupied != "OWNER OCCUPIED") %>%
  # clean owner mail address field
  mutate(OWNER_MAIL_ADDR = str_remove_all(OWNER_MAIL_ADDR, ","),
         OWNER_MAIL_ADDR = str_remove_all(OWNER_MAIL_ADDR, coll(".")),
         OWNER_MAIL_ADDR = str_remove_all(OWNER_MAIL_ADDR, "#"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bSTE\\b", "SUITE"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, " - ", "-"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bAVENUE\\b|\\bAVE\\b", "AV"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bLANE\\b|\\bLN\\b", "LA"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bROAD\\b", "RD"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bBOULEVARD\\b|\\bBLVD\\b", "BL"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bCOURT\\b", "CT"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bSTREET\\b", "ST"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bPARKWAY\\b|\\bPKWY\\b", "PK"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bTERRACE\\b", "TR"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bWAY\\b", "WA"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bDRIVE\\b", "DR"),
         OWNER_MAIL_ADDR = str_replace(OWNER_MAIL_ADDR, "\\bCIRCLE\\b|\\bCIR\\b", "CR"),
         OWNER_MAIL_ADDR = str_squish(OWNER_MAIL_ADDR)) %>%
  # clean owner city, state field
  mutate(OWNER_CITY_STATE = str_remove_all(OWNER_CITY_STATE, ","),
         OWNER_CITY_STATE = str_remove_all(OWNER_CITY_STATE, coll(".")),
         OWNER_CITY_STATE = str_remove_all(OWNER_CITY_STATE, "#"),
         OWNER_CITY_STATE = str_squish(OWNER_CITY_STATE)) %>%
  # clean owner name field, just use OWNER_NAME_1 for now
  mutate(OWNER_NAME_1 = str_remove_all(OWNER_NAME_1, ","),
         OWNER_NAME_1 = str_remove_all(OWNER_NAME_1, coll(".")),
         OWNER_NAME_1 = str_remove_all(OWNER_NAME_1, "#"),
         OWNER_NAME_1 = str_replace(OWNER_NAME_1, " - ", "-"),
         OWNER_NAME_1 = str_squish(OWNER_NAME_1),
         OWNER_NAME_1 = str_replace(OWNER_NAME_1, "\\bLL$", "LLC")) %>%
  # create combined owner address field
  mutate(owner_address = paste(OWNER_MAIL_ADDR, OWNER_CITY_STATE, sep = ", "))

write_csv(residential.landlord, "data/mprop/ResidentialProperties_NotOwnerOccupied.csv")
