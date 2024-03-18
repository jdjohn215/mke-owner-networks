rm(list = ls())

library(tidyverse)

# network information after the NEWEST update
updated.network <- read_csv("data/final-output/LandlordProperties-with-OwnerNetworks.csv")

# network information from the 2nd-to-last update
old.networks <- read_csv("data/network-components.csv.gz")

# changes in networks (new networks or changed networks)
new.changes <- anti_join(updated.network, old.networks)
old.changes <- anti_join(old.networks, updated.network)
changed.groups <- c(unique(new.changes$final_group), unique(old.changes$final_group))

# summary statistics by owner group
owner.networks <- updated.network %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = paste(unique(mprop_name), collapse = "; "),
            name_count = n_distinct(mprop_name)) %>%
  arrange(desc(parcels))

################################################################################
# owner networks whose graph's need updated
networks.to.update <- updated.network %>%
  filter(final_group %in% changed.groups) %>%
  group_by(final_group) %>%
  filter(n_distinct(mprop_name) > 1) %>%
  pull(final_group) %>%
  unique()

################################################################################
# count of nodes in each network
network.node.total <- updated.network |>
  filter(final_group %in% networks.to.update) |>
  group_by(final_group) |> 
  summarise(mprop_names = n_distinct(mprop_name), 
            mprop_addresses = n_distinct(mprop_address), 
            wdfi_addresses = n_distinct(wdfi_address[!is.na(wdfi_address)])) |> 
  mutate(nodes = mprop_names + mprop_addresses + wdfi_addresses)

source("analysis-scripts/VisualizeNetworkGraphs.R")
plot_save_network_graph <- function(name){
  
  network.nodes <- network.node.total$nodes[network.node.total$final_group == name]
  out.dim <- case_when(
    network.nodes < 5 ~ 4,
    network.nodes < 8 ~ 6,
    network.nodes < 21 ~ 8,
    network.nodes < 31 ~ 10,
    network.nodes < 61 ~ 12,
    network.nodes < 91 ~ 14,
    TRUE ~ 16
  )
  title.wrap <- case_when(
    network.nodes < 5 ~ 27,
    network.nodes < 8 ~ 41,
    network.nodes < 21 ~ 52,
    network.nodes < 31 ~ 67,
    network.nodes < 61 ~ 81,
    network.nodes < 91 ~ 270,
    TRUE ~ 16
  )
  
  gg1 <- visualize_network_graph(data = updated.network, 
                                 final_group_name = name,
                                 fontsize = 2, layout = "kk") +
    labs(title = str_wrap(name, title.wrap),
         subtitle = paste("includes", owner.networks$parcels[owner.networks$final_group == name], "parcels,",
                          owner.networks$units[owner.networks$final_group == name], "units, and",
                          owner.networks$name_count[owner.networks$final_group == name], "distinct owner names."))
  ggsave(paste0("images/networks-svg/", owner.networks$final_group[owner.networks$final_group == name], ".svg"),
         width = out.dim, height = if_else(out.dim < 8, out.dim + 1, out.dim))
}

map(networks.to.update, plot_save_network_graph, .progress = TRUE)
################################################################################
# save the newly updated network information
networks.updated <- updated.network %>% 
  select(TAXKEY, mprop_name, mprop_address, wdfi_address, final_group)

write_csv(networks.updated, "data/network-components.csv.gz")


################################################################################
# delete outdated files
current.file.names <- updated.network %>%
  group_by(final_group) %>%
  filter(n_distinct(mprop_name) > 1) %>%
  mutate(file_name = paste0(final_group, ".svg")) %>%
  pull(file_name) %>%
  unique()

all.files <- list.files("images/networks-svg/")
unlink(paste0("images/networks-svg/", all.files[! all.files %in% current.file.names]))
