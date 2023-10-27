rm(list = ls())

library(tidyverse)

mprop.orig <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied.csv")
mprop <- read_csv(here::here("data/mprop/Parcels_with_Ownership_Groups.csv")) %>%
  rename(mprop_name = OWNER_NAME_1, mprop_address = owner_address, 
         mprop_group = owner_group_name)
wdfi <- read_csv(here::here("data/wdfi/wdfi_agent_groups.csv"))

# only keep networks connection multiple MPROP-matched corporations
wdfi.connected <- wdfi |>
  group_by(wdfi_group_id) |>
  filter(n_distinct(corp_name_clean) > 1) |>
  ungroup()

mprop.groups.joined.by.wdfi.group <- mprop %>%
  group_by(mprop_name, mprop_group) %>%
  summarise() %>%
  ungroup() %>%
  inner_join(wdfi.connected, by = c("mprop_name" = "corp_name_clean")) %>%
  group_by(wdfi_group_id) %>%
  # filter results for instances where multiple owner_groups are matched
  filter(n_distinct(mprop_group) > 1) %>%
  group_by(wdfi_group_id, mprop_group) %>%
  summarise(mprop_names = n_distinct(mprop_name)) %>%
  ungroup()

# connect each node to its network group by assigning a numeric ID
f <- function(x, d){
  m <- merge(d, d[d$wdfi_group_id %in% x, "mprop_group"])
  if(length(unique(m$wdfi_group_id)) == length(x)) {
    return(m %>%
             group_by_all() %>%
             summarise(.groups = "drop") %>%
             mutate(group_contents = paste(sort(c(unique(mprop_group), unique(wdfi_group_id))), collapse = "; ")))
  } else {
    f(unique(m$wdfi_group_id), d)
  }
}

nodes.to.ids <- map_df(unique(mprop.groups.joined.by.wdfi.group$wdfi_group_id), f,
                       d = mprop.groups.joined.by.wdfi.group, .progress = T) %>%
  arrange(group_contents) %>%
  group_by(group_contents) %>%
  mutate(rownum = row_number()) %>%
  ungroup() %>%
  mutate(wdfi_mprop_group_id = cumsum(rownum == 1)) %>%
  select(mprop_group, wdfi_group_id, wdfi_mprop_group_id)

combined.wdfi.mprop.groups <- nodes.to.ids %>%
  group_by(mprop_group, wdfi_mprop_group_id) %>%
  summarise(.groups = "drop") %>%
  right_join(mprop) %>%
  group_by(wdfi_mprop_group_id) %>%
  # rename group with most frequent mprop_name value
  mutate(final_group = paste(names(which.max(table(mprop_name))), "Group")) %>%
  ungroup() %>%
  # preserve old mprop_group name if the group is still the original mprop-derived group
  mutate(final_group = if_else(is.na(wdfi_mprop_group_id),
                               mprop_group, final_group)) %>%
  left_join(wdfi.connected, by = c("mprop_name" = "corp_name_clean")) %>%
  mutate(final_group_source = if_else(is.na(wdfi_mprop_group_id),
                                      "mprop", "combo")) %>%
  select(TAXKEY, HOUSE_NR_LO, HOUSE_NR_HI, SDIR, STREET, STTYPE, HOUSE_NR_SFX,
         mprop_name, mprop_address, wdfi_address = address_city,
         wdfi_group_id, final_group, final_group_source) %>%
  # add additional fields
  left_join(mprop.orig %>%
              select(TAXKEY, NR_UNITS, GEO_ZIP_CODE, GEO_ALDER, LAND_USE_GP, owner_occupied,
                     C_A_CLASS, C_A_TOTAL, OWNER_NAME_2, OWNER_NAME_3))

write_csv(combined.wdfi.mprop.groups, "data/LandlordProperties-with-OwnerNetworks.csv")
