# Run this script to identify connected owner names and addresses
#   uses both MPROP and WDFI records to build networks
library(tidyverse)
library(tidygraph)

# clean, landlord-owned parcel data
mprop <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied_StandardizedAddresses.csv")

# WDFI corporate registrations for owners who appear in the MPROP file
wdfi <- vroom::vroom("data/wdfi/wdfi-current-in-mprop_StandardizedAddresses.csv")

# connect MPROP to WDFI
mprop.with.wdfi.matches <- mprop %>%
  # join by name
  left_join(wdfi %>%
              select(corp_name_clean, wdfi_address = principal_office_address),
            by = c("mprop_name" = "corp_name_clean"))

# built the undirected graph of all parcels and extract the components
#   each component is a distinct owner network
components <- mprop.with.wdfi.matches %>%
  select(mprop_name, mprop_address, wdfi_address) %>%
  pivot_longer(cols = -mprop_name, values_to = "address") %>%
  filter(!is.na(address)) %>%
  select(from = mprop_name, to = address) %>%
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
                               false = first(mprop_name)))

write_csv(mprop.with.networks, "data/LandlordProperties-with-OwnerNetworks.csv")

# View network summary stats
network.summary.stats <- mprop.with.networks %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = paste(unique(mprop_name), collapse = "; "),
            name_count = n_distinct(mprop_name)) %>%
  ungroup()
