rm(list = ls())

library(tidyverse)
library(gt)

df <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")

size.by.parcel <- df %>%
  group_by(final_group) %>%
  mutate(final_group_size = n()) %>%
  ungroup() %>%
  mutate(final_group_size_category = case_when(
    final_group_size == 1 ~ "1",
    final_group_size < 11 ~ "2-10",
    final_group_size < 26 ~ "11-25",
    final_group_size < 101 ~ "26-100",
    final_group_size < 501 ~ "101-500",
    TRUE ~ "more than 500"
  ),
  final_group_size_category = fct_reorder(final_group_size_category, final_group_size)) %>%
  group_by(final_group_size_category) %>%
  summarise(networks_count = n_distinct(final_group),
            parcels_count = n()) %>%
  mutate(networks_pct = (networks_count/sum(networks_count))*100,
         parcels_pct = (parcels_count/sum(parcels_count))*100) %>%
  select(final_group_size_category, starts_with("networks"), starts_with("parcels"))

gt(size.by.parcel, rowname_col = "final_group_size_category") %>%
  tab_spanner_delim("_") %>%
  fmt_number(columns = contains("count"), decimals = 0) %>%
  fmt_percent(columns = contains("pct"), decimals = 0, scale_values = F) %>%
  tab_stubhead("parcels owned") %>%
  tab_header(title = "Milwaukee landlord networks",
             subtitle = md("by **parcels** owned"))


size.by.units <- df %>%
  group_by(final_group) %>%
  mutate(final_group_size = sum(NR_UNITS)) %>%
  ungroup() %>%
  mutate(final_group_size_category = case_when(
    final_group_size < 3 ~ "1-2",
    final_group_size < 11 ~ "3-10",
    final_group_size < 26 ~ "11-25",
    final_group_size < 101 ~ "26-100",
    final_group_size < 501 ~ "101-500",
    TRUE ~ "more than 500"
  ),
  final_group_size_category = fct_reorder(final_group_size_category, final_group_size)) %>%
  group_by(final_group_size_category) %>%
  summarise(networks_count = n_distinct(final_group),
            units_count = sum(NR_UNITS)) %>%
  mutate(networks_pct = (networks_count/sum(networks_count))*100,
         units_pct = (units_count/sum(units_count))*100) %>%
  select(final_group_size_category, starts_with("networks"), starts_with("units"))

gt(size.by.units, rowname_col = "final_group_size_category") %>%
  tab_spanner_delim("_") %>%
  fmt_number(columns = contains("count"), decimals = 0) %>%
  fmt_percent(columns = contains("pct"), decimals = 0, scale_values = F) %>%
  tab_stubhead("units owned") %>%
  tab_header(title = "Milwaukee landlord networks",
             subtitle = md("by **units** owned"))

