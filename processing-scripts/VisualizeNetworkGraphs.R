rm(list = ls())

library(tidyverse)
library(tidygraph)
library(ggraph)

# parcels with all connections required to reconstruct networks
df <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")


###############################################################################

visualize_network_graph <- function(data, final_group_name, layout = "lgl", seed = 42){
  
  # subset the parcels for this network
  parcels <- df %>%
    filter(final_group == final_group_name) %>%
    select(TAXKEY, mprop_name, mprop_address, wdfi_address) %>%
    # append a suffix to make WDFI addresses distinct from MPROP addresses
    mutate(wdfi_address = if_else(!is.na(wdfi_address),
                                  true = paste(wdfi_address, "a", sep = "-"),
                                  false = NA_character_))
  
  # create all node connections
  #   * mprop name TO mprop address
  #   * mprop name TO wdfi address
  connections <- bind_rows(
    parcels %>%
      select(from = mprop_name, to = mprop_address),
    parcels %>%
      filter(!is.na(wdfi_address)) %>%
      select(from = mprop_name, to = wdfi_address)
  )
  
  # frequency of each node
  node.frequency <- parcels %>%
    pivot_longer(cols = everything(), names_to = "type", values_to = "name") %>%
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
    geom_node_label(aes(label = str_wrap(str_remove(name, "-a\\b"), 20)), 
                    size = if_else(nrow(node.frequency) > 75, 1.5, 2),
                    repel = T, segment.color = "gray75", min.segment.length = 0.25,
                    segment.size = 0.25,
                    fill = alpha(c("white"),0.5), max.overlaps = 50) +
    guides(size = "none") +
    theme_graph() +
    theme(legend.position = "top",
          legend.title = element_blank())
}

visualize_network_graph(df, "3325 S 26TH LLC Group")
visualize_network_graph(df, "VB ONE LLC Group", seed = 5)

