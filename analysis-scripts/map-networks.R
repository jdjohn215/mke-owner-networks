rm(list = ls())

library(tidyverse)
library(sf)
library(leaflet)

df <- read_csv("data/LandlordProperties-with-OwnerNetworks.csv")

map_network <- function(network){
  
  # parcels from the desired network, accepts either network name or component #
  df.network <- df %>%
    filter(final_group == network |
             component_number == network)
  
  # summarize by coordinates. Some parcels have the same coordinates
  coords <- df.network %>%
    # make address string
    mutate(housenum = if_else(HOUSE_NR_LO == HOUSE_NR_HI,
                              true = as.character(HOUSE_NR_LO),
                              false = paste(HOUSE_NR_LO, HOUSE_NR_HI, sep = "-")),
           housenum = if_else(is.na(HOUSE_NR_SFX),
                              true = housenum,
                              false = paste0(housenum, ", unit", HOUSE_NR_SFX, ",")),
           address = paste(housenum, SDIR, STREET, STTYPE)) %>%
    group_by(lon, lat) %>%
    summarise(label = if_else(n() > 1,
                              true = paste(n(), "parcels containing", sum(NR_UNITS), "units <br>",
                                           "owner network:", first(final_group)),
                              false = paste(first(address), "<br>",
                                            "unit(s):", first(NR_UNITS), "<br>",
                                            "owner network:", first(final_group), "<br>",
                                            "parcel owner:", first(mprop_name))),
              units = sum(NR_UNITS)) %>%
    ungroup() %>%
    # convert to simple features object
    st_as_sf(coords = c("lon", "lat"), crs = 4326)
  
  # leaflet map
  leaflet(coords) %>%
    addProviderTiles(providers$CartoDB.Positron) %>% # simpler than default tile server
    addCircleMarkers(radius = ~sqrt(units),
                     popup = ~lapply(label, htmltools::HTML),
                     label = ~lapply(label, htmltools::HTML))
}


map_network(51) # berrada
