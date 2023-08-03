# Run this script to identify connected owner names and addresses

library(tidyverse)
options(dplyr.summarise.inform = FALSE)

df <- read_csv("data/mprop/ResidentialProperties_NotOwnerOccupied.csv")

owner.names <- df %>%
  group_by(OWNER_NAME_1) %>%
  summarise(count = n()) %>%
  arrange(desc(count))

# returns a list of names connected by address/name network to the given name
owner_group_names <- function(x, d=df) {
  # obtain all the names sharing an address with the first name
  m <- unique(merge(d, d[d$OWNER_NAME_1 %in% x, c("OWNER_MAIL_ADDR", "OWNER_CITY_STATE")])[, 'OWNER_NAME_1'])
  
  # run the function recursively until the output is the same length as the output
  if (identical(length(m), length(x))) {
    return(x)
  } else {
    owner_group_names(m, d)
  }
}

# demo
owner_group_names("VB SIX LLC")

# returns a list of parcels owned by a list of names (e.g., the output of owner_group_names)
# name the owner group by picking the most frequent OWNER_NAME_1 value
owner_group_parcels <- function(owner_names, d = df){
  owner.group.parcels <- d %>%
    select(TAXKEY, OWNER_NAME_1) %>%
    filter(OWNER_NAME_1 %in% owner_names) %>%
    # if multiple names, name ownership group after the most frequent OWNER_NAME_1 value
    mutate(owner_group_name = if_else(length(owner_names) > 1,
                                      true = paste(names(which.max(table(OWNER_NAME_1))), "Group"),
                                      false = first(OWNER_NAME_1)))
  
  owner.group.parcels
}

owner_group_names("VB SIX LLC") %>%
  owner_group_parcels()

# owner names which haven't yet been assigned a group
# this object will be updated as the function runs
owner.names.without.owner.group <- owner.names

# use this function to cycle through all owner names, removing the ones that have
#   already been assigned an owner group
return_owner_group <- function(owner_name){
  unmatched.parcels <- df %>% filter(OWNER_NAME_1 %in% owner.names.without.owner.group$OWNER_NAME_1)
  connected.owner.names <- owner_group_names(owner_name,
                                             d = unmatched.parcels)
  
  # update the external object with the list of owner names that haven't been assigned a group
  updated.names.wthout.owner.group <- owner.names.without.owner.group %>%
    filter(! OWNER_NAME_1 %in% connected.owner.names)
  assign("owner.names.without.owner.group", updated.names.wthout.owner.group,
         envir = .GlobalEnv)
  
  owner_group_parcels(connected.owner.names,
                      d = unmatched.parcels)
}

# this line takes ~20 minutes to run
all.owner.groups <- map_df(owner.names.without.owner.group$OWNER_NAME_1,
                           return_owner_group, .progress = T)
write_csv(all.owner.groups, "data/mprop/Parcels_with_Ownership_Groups.csv")
