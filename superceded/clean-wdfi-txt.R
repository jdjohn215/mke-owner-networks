rm(list = ls())

library(tidyverse)
# For column definitions see: https://dfi.wi.gov/Pages/BusinessServices/BusinessEntities/FAQ.aspx

# The source file is too large for github and is ignored
# download via dropbox here: https://www.dropbox.com/s/20qhwxve30trz0p/20230703-220001-COMFicheX.txt?dl=0

# read the original txt file
# place all data in 1 column, preserving original spacing
wdfi <- vroom::vroom_fwf("data/wdfi/20230703-220001-COMFicheX.txt",
                         col_positions = fwf_widths(134),
                         skip_empty_rows = F, trim_ws = F, n_max = 5788383,
                         locale = locale(encoding = "latin1")) %>%
  mutate(wdfi_rownum = row_number())


# remove information which appears on each "page" of the output
wdfi.2 <- wdfi %>%
  filter(str_detect(X1, "REGISTERED AGENT                      ADDRESS                          CITY                       CAP  STATE ZIP         AND DATE|DATE 07/03/2023|REGISTERED AGENT                      ADDRESS                          CITY                       CAP  STATE ZIP         AND DATE|CORPORATION NAME                                                        CORP NO. CORP TYPE         PAID DATE INCORP   CURRENT STATUS",
                    negate = T) | is.na(X1))

# identify lines for each entity record
wdfi.3 <- wdfi.2 %>%
  # remove sequential NA rows, leaving 1 NA row between each entity
  filter(! (is.na(X1) & is.na(lag(X1, n = 1)))) %>%
  # assign a unique numeric identifier to the rows for each entity
  mutate(entity_id = if_else(is.na(lead(X1, 1)),
                             true = row_number(),
                             false = NA_real_),
         entity_id = as.numeric(factor(entity_id)),
         entity_id = zoo::na.locf(entity_id, fromLast = T)) %>%
  # drop empty rows separating entity listings
  filter(!is.na(X1)) %>%
  # add rownumber for entity listing
  group_by(entity_id) %>%
  mutate(entity_rownum = row_number()) %>%
  ungroup()
table(wdfi.3$entity_rownum)


# extract the elements from each entity's 1st row
row1 <- wdfi.3 %>%
  filter(entity_rownum == 1) %>%
  separate(X1, into = c("corp_name", "corp_num", "wdfi_id", "corp_type",
                        "date_incorp", "current_status", "status_date"),
           sep = c(69,72,81,104,118,122)) %>%
  mutate(across(.cols = where(is.character), .fns = str_squish))

# extract the elements from each entity's 2nd row
row2 <- wdfi.3 %>%
  filter(entity_rownum == 2) %>%
  separate(X1, into = c("registered_agent", "address_line1", "city", "state",
                        "zip"),
           sep = c(39,72,104,107)) %>%
  mutate(across(.cols = where(is.character), .fns = str_squish))

# extract the elements from each entity's 3rd row
row3 <- wdfi.3 %>%
  filter(entity_rownum == 3) %>%
  separate(X1, into = c("address_line2", "paid_cap"),
           sep = c(72)) %>%
  mutate(across(.cols = where(is.character), .fns = str_squish))

# combine all rows
clean.wdfi <- row1 %>%
  select(-c(wdfi_rownum, entity_rownum)) %>%
  inner_join(
    row2 %>%
      select(-c(wdfi_rownum, entity_rownum))
  ) %>%
  inner_join(
    row3 %>%
      select(-c(wdfi_rownum, entity_rownum))
  ) %>%
  select(wdfi_id, everything()) %>%
  mutate(date_incorp = as.Date(date_incorp, format = "%m/%d/%Y"),
         status_date = as.Date(status_date, format = "%m/%d/%Y"))

# check for duplicates
# there is 1 duplicate which is present in the original WDFI data - wdfi_id "P 074882"
n_distinct(clean.wdfi$entity_id) == n_distinct(clean.wdfi$wdfi_id)
n_distinct(clean.wdfi$entity_id) == nrow(clean.wdfi)
clean.wdfi %>%
  group_by(wdfi_id) %>%
  filter(n() > 1)

# remove duplicate entity entries, keeping the most recent status date
clean.wdfi.deduplicated <- clean.wdfi %>%
  group_by(wdfi_id) %>%
  slice_max(order_by = status_date, n = 1, with_ties = F) %>%
  ungroup()

write_csv(clean.wdfi.deduplicated, "data/wdfi/WDFI_2023-07-03.csv.gz")
