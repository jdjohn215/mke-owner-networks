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

# connect MPROP to WDFI
mprop.with.wdfi.matches <- mprop %>%
  # join by name
  left_join(wdfi %>%
              select(corp_name_clean, wdfi_address = principal_office_address),
            by = c("mprop_name" = "corp_name_clean")) %>%
  # add suffixes to addresses that make them distinct
  mutate(mprop_address = paste(mprop_address, "mprop", sep = "_"),
         wdfi_address = if_else(is.na(wdfi_address), wdfi_address,
                                paste(wdfi_address, "wdfi", sep = "_")))

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
  inner_join(component.membership, by = c("mprop_name" = "name")) %>%
  # create a descriptive name for each parcel, which is the most frequently used mprop_name value
  group_by(component_number) %>%
  mutate(final_group = if_else(n_distinct(mprop_name) > 1,
                               true = paste(names(which.max(table(mprop_name))), "Group"),
                               false = first(mprop_name)),
         final_group = str_replace_all(final_group, coll("/"), "-")) |>
  ungroup()

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
dns.taxkey.during.current.ownership <- mprop.with.networks |>
  select(TAXKEY, final_group, CONVEY_DATE) |>
  inner_join(dns) |>
  filter(date_inspection > CONVEY_DATE) |>
  group_by(TAXKEY) |>
  summarise(ownership_orders = n_distinct(record_id),
            ownership_violations = sum(violations),
            .groups = "drop")

mprop.with.dns <- mprop.with.networks |>
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
  mutate(across(.cols = where(is.numeric), .fns = ~replace(.x, is.na(.x), 0)))

# calculate network summary stats
network.summary.stats <- mprop.with.dns %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = paste(unique(mprop_name), collapse = "; "),
            name_count = n_distinct(mprop_name),
            dns_covered_unit_years = sum(dns_covered_unit_years),
            across(.cols = contains("orders"), .fns = sum),
            across(.cols = contains("violations"), .fns = sum)) |>
  mutate(ownership_violation_unit_rate_annual = ownership_violations/dns_covered_unit_years*100) |>
  select(final_group, component_number, parcels, units, names, name_count, dns_covered_unit_years, starts_with("ownership"), starts_with("total"))

################################################################################
# save output
write_csv(mprop.with.dns, "data/LandlordProperties-with-OwnerNetworks.csv")
write_csv(network.summary.stats, "data/Landlord-network-summary-statistics.csv")

