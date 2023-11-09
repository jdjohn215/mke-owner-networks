rm(list = ls())

library(tidyverse)
library(tidygraph)
library(ggraph)

# parcels with all connections required to reconstruct networks
df <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")

owner.networks <- df %>%
  group_by(component_number, final_group) %>%
  summarise(parcels = n(),
            units = sum(NR_UNITS),
            names = paste(unique(mprop_name), collapse = "; "),
            name_count = n_distinct(mprop_name))

###############################################################################

visualize_network_graph <- function(data, final_group_name, layout = "lgl", seed = 42){
  
  # subset the parcels for this network
  parcels <- data %>%
    filter(final_group == final_group_name) %>%
    select(TAXKEY, mprop_name, mprop_address, wdfi_address)
  
  addresses.in.both <- parcels %>%
    filter(str_sub(mprop_address, 1, -7) %in% str_sub(wdfi_address, 1, -6)) %>%
    mutate(matched_address = str_sub(mprop_address, 1, -7)) %>%
    pull(matched_address) %>%
    unique()
  
  # create all node connections
  #   * mprop name TO mprop address
  #   * mprop name TO wdfi address
  #   * mprop address TO wdfi address
  connections <- parcels %>%
    select(mprop_name, mprop_address, wdfi_address) %>%
    pivot_longer(cols = -mprop_name, values_to = "address") %>%
    filter(!is.na(address)) %>%
    select(from = mprop_name, to = address) %>%
    # add connections which are MPROP address to WDFI address
    bind_rows(
      tibble(
        from = stringi::stri_join(paste0(addresses.in.both, "_mprop")),
        to =  stringi::stri_join(addresses.in.both, "_wdfi")
      )
    )
  
  # frequency of each node
  node.frequency <- parcels %>%
    select(-TAXKEY) %>%
    pivot_longer(cols = everything(), names_to = "type", values_to = "name") %>%
    filter(!is.na(name)) %>%
    group_by(name) %>%
    summarise(node_frequency = n())
  
  # create the graph object using tidygraph
  graph <- as_tbl_graph(connections) %>%
    # add attributes
    mutate(node_class = case_when(
      name %in% parcels$mprop_name ~ "owner name",
      name %in% parcels$mprop_address ~ "mprop address",
      name %in% parcels$wdfi_address ~ "wdfi address"
    )) %>%
    inner_join(node.frequency)
  
  # control randomness of graph layout
  set.seed(seed)
  ggraph(graph, layout = layout) + 
    geom_edge_link() + 
    geom_node_point(aes(color = node_class, shape = node_class, size = node_frequency)) +
    geom_node_label(aes(label = str_wrap(str_remove(name, "_mprop|_wdfi"), 20)), 
                    size = if_else(nrow(node.frequency) > 75, 1.5, 2),
                    repel = T, segment.color = "gray75", min.segment.length = 0.25,
                    segment.size = 0.25,
                    fill = alpha(c("white"),0.5), max.overlaps = 50) +
    guides(size = "none") +
    theme_graph() +
    theme(legend.position = "top",
          legend.title = element_blank())
}

################################################################################
# DEMOS
# visualize_network_graph(df, "RESIDENTIAL PROPERTIES RESOU Group", seed = 4)
# visualize_network_graph(df, "CB MEADOW VILLAGE RENOVATION Group")
# visualize_network_graph(df, "VB ONE LLC Group", seed = 5)
# visualize_network_graph(df, "CITY OF MILWAUKEE Group")
# 
# s2.network.graph <- visualize_network_graph(df, "S2 REAL ESTATE GROUP 5 LLC Group")
# ggsave("images/S2-Network.png", plot = s2.network.graph, width = 14, height = 10)
