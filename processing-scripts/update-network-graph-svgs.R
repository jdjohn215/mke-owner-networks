rm(list = ls())

library(tidyverse)

# network information after the NEWEST update
updated.network <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")

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

source("analysis-scripts/VisualizeNetworkGraphs.R")
plot_save_network_graph <- function(name){
  gg1 <- visualize_network_graph(data = updated.network, 
                                 final_group_name = name,
                                 fontsize = 2, layout = "kk") +
    labs(title = name,
         subtitle = paste("includes", owner.networks$parcels[owner.networks$final_group == name], "parcels,",
                          owner.networks$units[owner.networks$final_group == name], "units, and",
                          owner.networks$name_count[owner.networks$final_group == name], "distinct owner names."))
  ggsave(paste0("images/networks-svg/", owner.networks$final_group[owner.networks$final_group == name], ".svg"),
         width = 8, height = 8)
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
