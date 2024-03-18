# Run this script to identify connected owner names and addresses
#   uses both MPROP and WDFI records to build networks
library(tidyverse)
library(tidygraph)

# clean, landlord-owned parcel data
mprop <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses_RepairedNames.csv")

# WDFI corporate registrations for owners who appear in the MPROP file
wdfi <- vroom::vroom("data/wdfi/wdfi-current-in-mprop_StandardizedAddresses.csv")

# addresses that shouldn't be used to make connections
useless.addresses <- read_csv("data/mprop/useless-addresses.csv")

# names that shouldn't be used to make additional connections
useless.names <- read_csv("data/mprop/useless-names.csv")
repeated.names <- read_csv("data/names/repeated-names.csv")
repeated.names.not.used.to.match <- mprop |>
  inner_join(repeated.names, by = c("mprop_name" = "name")) |>
  group_by(mprop_name) |>
  summarise(addresses = n_distinct(mprop_address)) |>
  filter(addresses > 1)
print(paste(nrow(repeated.names.not.used.to.match), "common names are not used for matching"))

# connect MPROP to WDFI
mprop.with.wdfi.matches <- mprop %>%
  # join by name
  left_join(wdfi %>%
              select(corp_name_clean, wdfi_address = principal_office_address),
            by = c("mprop_name" = "corp_name_clean")) %>%
  # add suffixes to addresses that make them distinct
  mutate(mprop_address = paste(mprop_address, "mprop", sep = "_"),
         wdfi_address = if_else(is.na(wdfi_address), wdfi_address,
                                paste(wdfi_address, "wdfi", sep = "_"))) |>
  # add suffix that makes common non-identifying names distinct
  mutate(mprop_name = if_else(mprop_name %in% repeated.names.not.used.to.match$name,
                              true = paste(mprop_name, row_number(), sep = "!!"),
                              false = mprop_name))

###############################################################################
# kinds of nodes
#   * mprop owner (also WDFI corp registration, when matched)
#   * mprop address (owner mailing address)
#   * wdfi address (principal office address from matched corporate registration)

# kinds of connections (graph edges)
#   * mprop owner TO mprop address  - via each row of the MPROP parcel file
#   * mprop owner TO wdfi address   - via mprop owner to wdfi corp direct match,
#                                     then use wdfi principal office address
#   * mprop address TO wdfi address - the MPROP address exactly matches the WDFI
#                                     principal office address

# these addresses appear in both MPROP and WDFI
addresses.in.both <- mprop.with.wdfi.matches %>%
  filter(str_sub(mprop_address, 1, -7) %in% str_sub(wdfi_address, 1, -6)) %>%
  mutate(matched_address = str_sub(mprop_address, 1, -7)) %>%
  pull(matched_address) %>%
  unique()

# built the undirected graph of all parcels and extract the components
#   each component is a distinct owner network
components <- mprop.with.wdfi.matches %>%
  mutate(mprop_address = if_else(str_remove(mprop_address, "_mprop") %in% useless.addresses$address |
                                   mprop_name %in% useless.names$name,
                                 true = paste(mprop_address, row_number(), sep = "-"),
                                 false = mprop_address),
         wdfi_address = if_else(str_remove(wdfi_address, "_wdfi") %in% useless.addresses$address |
                                  mprop_name %in% useless.names$name,
                                true = paste(wdfi_address, row_number(), sep = "-"),
                                false = wdfi_address)) %>%
  select(mprop_name, mprop_address, wdfi_address) %>%
  pivot_longer(cols = -mprop_name, values_to = "address") %>%
  filter(!is.na(address)) %>%
  select(from = mprop_name, to = address) %>%
  # add connections which are MPROP address to WDFI address
  bind_rows(
    tibble(
      from = paste(addresses.in.both, "mprop", sep = "_"),
      to =  paste(addresses.in.both, "wdfi", sep = "_")
    )
  ) %>%
  # convert to graph object
  as_tbl_graph() %>%
  # convert to igraph
  as.igraph() %>%
  # identify components of graph
  igraph::components()



# extract component number for each node
component.membership <- tibble(name = names(components$membership),
                               component_number = components$membership)

# add component ID number to parcel data
mprop.with.networks <- mprop.with.wdfi.matches %>%
  inner_join(component.membership, by = c("mprop_name" = "name")) |>
  # remove common name flag
  mutate(mprop_name = word(mprop_name, 1, sep = "!!"))

# add descriptive names to each network
#   if one unique name in group, then MPROP_NAME
#   if 2-3 unique names in group, the list of names delimited by -- and ending with "Group"
#   if >3 unique names, then most common name followed by "etc Group"
final.group.names <- mprop.with.networks |>
  # add address to common names that couldn't be used for matches by themselves
  mutate(mprop_name2 = if_else(mprop_name %in% repeated.names.not.used.to.match$mprop_name,
                               true = paste(mprop_name, str_remove(mprop_address, "_mprop"), sep = " -- "),
                               false = mprop_name)) |>
  group_by(component_number, mprop_name2) |>
  summarise(count = n()) |>
  arrange(component_number, desc(count), mprop_name2) |>
  group_by(component_number) |>
  mutate(name_count = n()) |>
  mutate(
    final_group = case_when(
      name_count == 1 ~ mprop_name2,
      name_count > 3 ~ paste(first(mprop_name2), "etc Group"),
      name_count < 4 ~ paste(paste(mprop_name2, collapse = " -- "), "Group")
    )) |>
  mutate(final_group = str_replace_all(final_group, coll("/"), "-")) |>
  group_by(final_group, component_number) |>
  summarise(.groups = "drop")

# verify each component number is uniquely named
n_distinct(final.group.names$final_group) == n_distinct(final.group.names$component_number)

mprop.with.networks.named <- mprop.with.networks |>
  inner_join(final.group.names)

################################################################################
# add DNS violation records
dns <- read_csv("data/dns-code-violations/all-orders-2017to2023.csv") |>
  rename(TAXKEY = taxkey)
dns.records.end <- as.Date("2023-12-31") # the last date for which DNS records are available

# calculate violations per TAXKEY
#   total violations at each TAXKEY for the entire period covered
dns.taxkey.total <- dns |>
  group_by(TAXKEY) |>
  summarise(total_orders = n(),
            total_violations = sum(violations))

#   count of violations ONLY during the period of current ownership
#     determined using the CONVEY_DATE field
dns.taxkey.during.current.ownership <- mprop.with.networks.named |>
  select(TAXKEY, final_group, CONVEY_DATE) |>
  inner_join(dns) |>
  filter(date_inspection > CONVEY_DATE) |>
  group_by(TAXKEY) |>
  summarise(ownership_orders = n_distinct(record_id),
            ownership_violations = sum(violations),
            .groups = "drop")

mprop.with.dns <- mprop.with.networks.named |>
  mutate(
    dns_covered_days = case_when(
      CONVEY_DATE < as.Date("2017-01-01") ~ as.numeric(difftime(dns.records.end, # instances where ownership *precedes* DNS record period
                                                                as.Date("2017-01-01"), 
                                                                units = "days")),
      CONVEY_DATE > dns.records.end ~ 0, # instances where ownership begins *after* DNS record period
      TRUE ~ as.numeric(difftime(dns.records.end, CONVEY_DATE, units = "days"))),
    dns_covered_unit_years = (dns_covered_days*NR_UNITS)/365.25) |>
  left_join(dns.taxkey.total) |>
  left_join(dns.taxkey.during.current.ownership) |>
  mutate(across(.cols = where(is.numeric), .fns = ~replace(.x, is.na(.x), 0)),
         # make sure dns coverage is NA if CONVEY_DATE is NA
         dns_covered_unit_years = if_else(is.na(CONVEY_DATE), NA, dns_covered_unit_years),
         dns_covered_days = if_else(is.na(CONVEY_DATE), NA, dns_covered_days))

################################################################################
# add eviction records
source("processing-scripts/retrieve_private_file_function.R")
eviction.filings <- read_csv(fetchGHdata(repo = "mke-evict-data",
                                         path = "processed-data/mke-evictions-w-taxkeys.csv")) |>
  #   just those cases successfully assigned to a TAXKEY
  filter(!is.na(TAXKEY),
         TAXKEY != 0) |>
  mutate(TAXKEY = str_pad(TAXKEY, width = 10, side = "left", pad = "0"))

mke.evictions <- eviction.filings |>
  mutate(eviction_order = if_else(lienType_desc != "Judgment for eviction" | 
                                    is.na(lienType_desc), "no", "yes")) |>
  select(TAXKEY, caseNo, filing_date, eviction_order) |>
  # remove the last 30 days, because I believe records to be incomplete
  filter(filing_date < max(filing_date) - 30)

# eviction records end date
eviction.records.end.date <- max(mke.evictions$filing_date)
eviction.records.start.date <- as.Date("2016-01-01")

#   count of violations ONLY during the period of current ownership
#     determined using the CONVEY_DATE field
evictions.taxkey.during.current.ownership <- mprop.with.networks.named |>
  select(TAXKEY, final_group, CONVEY_DATE) |>
  inner_join(mke.evictions) |>
  filter(filing_date > CONVEY_DATE) |>
  group_by(TAXKEY) |>
  summarise(evict_filings = n(),
            evict_orders = sum(eviction_order == "yes"), .groups = "drop")

mprop.with.evictions <- mprop.with.dns |>
  # calculate the exposure (unit-years during the period for which eviction records are available)
  mutate(
    evict_covered_days = case_when(
      CONVEY_DATE > eviction.records.end.date ~ 0, # property acquired *after* eviction records end
      CONVEY_DATE < eviction.records.start.date ~ as.numeric(difftime(eviction.records.end.date, # property acquired *before* eviction records begin
                                                                      eviction.records.start.date),
                                                             units = "days"),
      TRUE ~ as.numeric(difftime(eviction.records.end.date, CONVEY_DATE, units = "days"))),
    evict_covered_unit_years = (evict_covered_days*NR_UNITS)/365.25) |>
  # join with eviction filing data by taxkey
  left_join(evictions.taxkey.during.current.ownership) |>
  mutate(across(.cols = contains("evict"), .fns = ~replace(.x, is.na(.x), 0)),
         # make sure dns coverage is NA if CONVEY_DATE is NA
         evict_covered_unit_years = if_else(is.na(CONVEY_DATE), NA, evict_covered_unit_years))

################################################################################
# calculate network summary stats
network.summary.stats <- mprop.with.evictions %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            total_assessed_value = sum(C_A_TOTAL),
            names = paste(unique(mprop_name), collapse = "; "),
            name_count = n_distinct(mprop_name),
            dns_covered_unit_years = sum(dns_covered_unit_years[!is.na(CONVEY_DATE)]),
            across(.cols = c(contains("total_orders"),contains("total_violations"),
                             contains("ownership_")),
                   .fns = ~sum(.x[!is.na(CONVEY_DATE)])),
            across(.cols = contains("evict"), .fns = ~sum(.x[!is.na(CONVEY_DATE)])),
            .groups = "drop") |>
  mutate(ownership_violation_unit_rate_annual = ownership_violations/dns_covered_unit_years*100,
         annual_evict_filing_rate_per_unit = (evict_filings/evict_covered_unit_years)*100,
         annual_evict_order_rate_per_unit = (evict_orders/evict_covered_unit_years)*100) |>
  select(final_group, component_number, parcels, units, names, name_count,
         starts_with("evict"), annual_evict_filing_rate_per_unit, annual_evict_order_rate_per_unit,
         dns_covered_unit_years, starts_with("ownership"), starts_with("total")) |>
  arrange(desc(units))

################################################################################
# redactions
network.summary.stats.redacted <- network.summary.stats |>
  mutate(across(.cols = contains("evict"),
                .fns = ~if_else(units > 5, .x, NA)))

# find networks with redacted filings where the number of redacted units is less than 6
redact.all.parcels <- mprop.with.evictions |>
  mutate(across(.cols = contains("evict"),
                .fns = ~if_else(NR_UNITS > 5, .x, NA))) |>
  group_by(final_group) |>
  summarise(redacted_parcels = sum(is.na(evict_filings)),
            redacted_units = sum(NR_UNITS[is.na(evict_filings)]),
            unredacted_filings = sum(evict_filings, na.rm = T)) |>
  inner_join(network.summary.stats.redacted |>
               select(final_group, total_parcels = parcels, total_filings = evict_filings)) |>
  filter(!is.na(total_filings)) |>
  select(final_group, total_parcels, total_filings, everything()) |>
  mutate(redacted_filings = total_filings - unredacted_filings) |>
  filter(redacted_units < 6,
         redacted_filings > 0)

mprop.with.evictions.redacted <- mprop.with.evictions |>
  mutate(across(.cols = c("evict_filings","evict_orders"),
                .fns = ~if_else(NR_UNITS > 5, .x, NA)),
         evict_filings = if_else(final_group %in% redact.all.parcels$final_group, NA, evict_filings),
         evict_orders = if_else(final_group %in% redact.all.parcels$final_group, NA, evict_orders))

################################################################################
# save output
write_csv(mprop.with.evictions.redacted, "data/final-output/LandlordProperties-with-OwnerNetworks.csv")
write_csv(network.summary.stats.redacted, "data/final-output/Landlord-network-summary-statistics.csv")

###############################################################################
# When were the data sources last updated?
updated <- tibble(
  mprop = max(as.Date(word(str_squish(mprop$LAST_VALUE_CHG), 1, 3), format = "%b %d %Y"), na.rm = T),
  wdfi = "2023-10-13", # update this after updating the corporate registration file
  workflow = as.Date(lubridate::with_tz(Sys.time(), tzone = "America/Chicago")),
  evict_start = eviction.records.start.date,
  evict_end = eviction.records.end.date,
  dns_start = "2017-01-01",
  dns_end = dns.records.end
)
write_csv(updated, "data/final-output/process-dates-updated.csv")
