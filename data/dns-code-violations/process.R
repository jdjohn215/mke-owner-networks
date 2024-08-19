library(tidyverse)

# DNS extract covering 2017-2022
#   1 year per sheet
read_dns_sheet <- function(sheetno){
  readxl::read_excel("data/dns-code-violations/violations_2017_2022.xlsx",
                     sheet = sheetno) |>
    janitor::clean_names()
}

dns.violations.17to22 <- map_df(1:6, read_dns_sheet)

# DNS extract covering 2023
dns.violations.23 <- readxl::read_excel("data/dns-code-violations/VIOLATIONS_2023.xlsx") |>
  janitor::clean_names() |>
  rename(violation_text = item_comment)

# DNS extract covering Q1 2024
dns.violations.24q1 <- readxl::read_excel("data/dns-code-violations/Violations_Jan1thruMarch312024.xlsx") |>
  janitor::clean_names() |>
  rename(violation_text = item_comment)

# DNS extract covering Q2 2024
dns.violations.24q2 <- readxl::read_excel("data/dns-code-violations/Violations_Apr_June_2024.xlsx") |>
  janitor::clean_names() |>
  rename(violation_text = item_comment, city = address_city, 
         state = address_state, zip = address_zip)

################################################################################
# combine DNS records
dns.all <- bind_rows(dns.violations.17to22, dns.violations.23, dns.violations.24q1, dns.violations.24q2)

dns.all.2 <- dns.all |>
  mutate(across(.cols = where(is.character), str_to_upper)) |>
  # remove certain outcomes
  filter(str_detect(record_status, "DISMISSED|WITHDRAWN|TEST|DUPLICATE|RAZED", negate = T)) |>
  # deduplicate
  group_by_all() |>
  summarise() |>
  ungroup() |>
  filter(between(date_inspection, as.Date("2017-01-01"), as.Date("2024-06-29"))) |>
  mutate(date_inspection = as.Date(date_inspection),
         record_open_date = as.Date(record_open_date),
         taxkey = str_pad(taxkey, width = 10, side = "left", pad = "0"))

# create file with 1 row per order and the count of violations in a column
dns.records <- dns.all.2 |>
  group_by(record_id, taxkey, date_inspection) |>
  summarise(violations = n_distinct(violation_text), .groups = "drop")

n_distinct(dns.records$taxkey)
sum(dns.records$violations)
ggplot(dns.records, aes(date_inspection)) + geom_histogram()

# total orders and violations by taxkey
by.taxkey <- dns.records |>
  group_by(taxkey) |>
  summarise(records = n(),
            violations = sum(violations))

################################################################################
# save output
write_csv(dns.all.2, "data/dns-code-violations/all-violations-latest.csv.gz")
write_csv(dns.records, "data/dns-code-violations/all-orders-latest.csv")
