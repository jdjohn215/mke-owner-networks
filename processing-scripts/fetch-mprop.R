library(tidyverse)
library(tidygeocoder)

# download the latest MPROP from the city's data portal
mprop.orig <- read_csv("https://data.milwaukee.gov/dataset/562ab824-48a5-42cd-b714-87e205e489ba/resource/0a2c7f31-cd15-4151-8222-09dd57d5f16d/download/mprop.csv")

# temporarily use the residential unit count retrieved from parcel polygons on
#   March 10, 2025. The assessor's office plans to add the residential unit field
#   to the MPROP file in the near future.
# ALSO, some HACM properties don't have any units in MPROP, add those
hacm.units <- read_csv("data/mprop/hacm-units.csv", col_types = "ccncc") |>
  filter(!is.na(TAXKEY)) |>
  select(TAXKEY, hacm_units = units)
residential.units <- read_csv("data/mprop/residential-units-from-parcel-polygons.csv") |>
  left_join(hacm.units) |>
  mutate(residential_units = if_else(!is.na(hacm_units), hacm_units, residential_units))

# some transformations
mprop <- mprop.orig %>%
  # substitute residential units
  left_join(residential.units) |>
  mutate(NR_UNITS = if_else(!is.na(residential_units), residential_units, NR_UNITS)) |>
  # construct custom owner-occupied variables
  mutate(
    # construct custom owner-occupied variables
    #   dummy variable indicating if property could potentially be owner-occupied
    potentially_owner_occupied = case_when(
      C_A_CLASS %in% c(1,5) ~ 1, # house or condo
      LAND_USE_GP == 4 & NR_UNITS < 5 ~ 1, # mixed commercial/residential & less than 5 units
      NR_UNITS > 0 ~ 1, # at least 1 residential unit
      TRUE ~ 0
    ),
    owner_occupied = case_when(
      # cannot be owner occupied if not a house or condo (or 1-4 unit mixed commercial/residential)
      potentially_owner_occupied == 0 ~ "not owner occupied",
      # owner-occupied if MPROP variable says so
      !is.na(OWN_OCPD) ~ "owner occupied",
      # cannot be owner occupied if zip codes don't match
      str_sub(OWNER_ZIP, 1, 5) != str_sub(GEO_ZIP_CODE, 1, 5) ~ "not owner occupied",
      # cannot be owner occupied if mailing address is PO BOX
      str_detect(string = str_remove_all(OWNER_MAIL_ADDR, "[.]"),
                 pattern = "\\bPO BOX\\b|\\bPO BOX\\b|\\bPOB\\b|\\bP O BOX\\b") ~ "not owner occupied",
      # is owner occupied if house numbers match
      suppressWarnings(parse_number(word(OWNER_MAIL_ADDR, 1, 1))) == HOUSE_NR_LO |
        suppressWarnings(parse_number(word(OWNER_MAIL_ADDR, 1, 1))) == HOUSE_NR_HI ~ "owner occupied",
      TRUE ~ "not owner occupied"
    )) %>%
  # subset columns
  select(TAXKEY, HOUSE_NR_LO, HOUSE_NR_HI, HOUSE_NR_SFX, SDIR, STREET, STTYPE,
         C_A_CLASS, LAND_USE_GP, C_A_TOTAL, NR_UNITS, residential_units, OWNER_NAME_1,
         OWNER_NAME_2, OWNER_NAME_3, CONVEY_DATE, OWNER_MAIL_ADDR, OWNER_CITY_STATE, OWNER_ZIP, GEO_ZIP_CODE,
         owner_occupied, ZONING, OWN_OCPD, GEO_ALDER, LAST_VALUE_CHG) %>%
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
           LAND_USE_GP %in% c("MIXED COMMERCIAL/RESIDENTIAL", "SINGLE FAMILY",
                            "DUPLEX", "MULTI-FAMILY", "MIXED COMMERCIAL"),
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
  mutate(OWNER_CITY_STATE = str_remove_all(OWNER_CITY_STATE, coll(".")),
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
  mutate(mprop_address_raw = paste(OWNER_MAIL_ADDR, OWNER_CITY_STATE, sep = ", "),
         mprop_address_raw = paste(mprop_address_raw, str_sub(OWNER_ZIP, 1, 5))) %>%
  rename(mprop_name = OWNER_NAME_1)

###############################################################################
# add coordinates
taxkey.coords <- read_csv("data/mprop/taxkey-coordinates.csv")

# get new coordinates from Geocodio if necessary, add them to the lookup table
needs.geocoding <- residential.landlord %>%
  filter(! TAXKEY %in% taxkey.coords$TAXKEY) %>%
  mutate(city = ", MILWAUKEE, WI") %>%
  unite("complete_address", HOUSE_NR_LO, SDIR, STREET, STTYPE, city, GEO_ZIP_CODE,
        na.rm = T, sep = " ") %>%
  select(TAXKEY, complete_address) %>%
  mutate(complete_address = str_replace(complete_address, " ,", ","))

if(nrow(needs.geocoding) > 0){
  geocoded <- geocode(.tbl = needs.geocoding,
                      address = complete_address,
                      full_results = FALSE,
                      method = "geocodio")
  taxkey.coords.updated <- geocoded %>%
    select(TAXKEY, lon = long, lat) %>%
    bind_rows(taxkey.coords)
} else {
  taxkey.coords.updated <- taxkey.coords
}

residential.landlord <- residential.landlord %>%
  left_join(taxkey.coords)

###############################################################################
# save data
write_csv(residential.landlord, "data/mprop/ResidentialProperties_NotOwnerOccupied.csv")
write_csv(taxkey.coords.updated, "data/mprop/taxkey-coordinates.csv")

