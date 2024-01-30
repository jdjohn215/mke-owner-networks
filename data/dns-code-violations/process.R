library(tidyverse)

# DNS extract covering 2017-2022
dns.violations.17to22 <- readxl::read_excel("data/dns-code-violations/violations_2017_2022.xlsx") |>
  janitor::clean_names()

# DNS extract covering 2023
dns.violations.23 <- readxl::read_excel("data/dns-code-violations/VIOLATIONS_2023.xlsx") |>
  janitor::clean_names() |>
  rename(violation_text = item_comment)

################################################################################
dns.all <- bind_rows(dns.violations.17to22, dns.violations.23) |>
  # deduplicate
  group_by_all() |>
  summarise() |>
  ungroup() |>
  mutate(date_inspection = as.Date(date_inspection),
         record_open_date = as.Date(record_open_date),
         taxkey = str_pad(taxkey, width = 10, side = "left", pad = "0"))

dns.records <- dns.all |>
  group_by(record_id, taxkey, record_open_date) |>
  summarise(violations = n_distinct(violation_text), .groups = "drop")

n_distinct(dns.records$taxkey)
sum(dns.records$violations)

by.taxkey <- dns.records |>
  group_by(taxkey) |>
  summarise(records = n(),
            violations = sum(violations))
