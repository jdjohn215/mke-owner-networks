# Run this script to identify connected owner names and addresses
#   uses both MPROP and WDFI records to build networks
library(tidyverse)
library(tidygraph)

# clean, landlord-owned parcel data
mprop <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied.csv")

# WDFI corporate registrations for owners who appear in the MPROP file
wdfi <- vroom::vroom("data/wdfi/wdfi-connected-to-mprop.csv")

# connect MPROP to WDFI
mprop.with.wdfi.matches <- mprop %>%
  # join by name
  left_join(wdfi, by = c("OWNER_NAME_1" = "corp_name_clean"))

# built the undirected graph of all parcels and extract the components
#   each component is a distinct owner network
components <- mprop.with.wdfi.matches %>%
  select(OWNER_NAME_1, owner_address, wdfi_address) %>%
  pivot_longer(cols = -OWNER_NAME_1, values_to = "address") %>%
  filter(!is.na(address)) %>%
  select(from = OWNER_NAME_1, to = address) %>%
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
mprop.with.networks <- mprop %>%
  inner_join(component.membership, by = c("OWNER_NAME_1" = "name")) %>%
  # create a descriptive name for each parcel, which is the most frequently used OWNER_NAME_1 value
  group_by(component_number) %>%
  mutate(final_group = if_else(n_distinct(OWNER_NAME_1) > 1,
                               true = paste(names(which.max(table(OWNER_NAME_1))), "Group"),
                               false = first(OWNER_NAME_1)))

write_csv(mprop.with.networks, "data/LandlordProperties-with-OwnerNetworks.csv")

# View network summary stats
network.summary.stats <- mprop.with.networks %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = paste(unique(OWNER_NAME_1), collapse = "; "),
            name_count = n_distinct(OWNER_NAME_1)) %>%
  ungroup()
