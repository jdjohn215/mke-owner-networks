rm(list = ls())

library(tidyverse)

# the current WDFI file
#   this includes entities in bad standing or delinquent but NOT YET terminated
wdfi.current <- vroom::vroom("data/wdfi/WDFI_Current_2023-07-03.csv.gz") %>%
  mutate(address_city = str_squish(str_remove_all(address_city, pattern = coll(","))))

# wdfi useless registered agents
wdfi.agents.not.useful <- readxl::read_excel("data/munges/WDFI_notes.xlsx",
                                      sheet = 1) %>%
  mutate(registered_agent = str_replace_all(registered_agent, "\\s", " "))

# wdfi addresses used by useless registered agents
wdfi.addresses.not.useful <- wdfi.current %>%
  filter(registered_agent %in% wdfi.agents.not.useful$registered_agent |
           str_detect(registered_agent, "\\bLAW\\b|\\bLAWYERS\\b|\\bLAWYER\\b|\\bATTORNEY\\b|\\TAX\\b|\\bACCOUNTING\\b|\\bINCORPORATING\\b|\\bAGENT\\b|\\bAGENTS\\b|CORPORATE SERV")) %>%
  group_by(address_city) %>%
  summarise()


# all the MPROP landlords
mprop.owners <- read_csv("data/mprop/Parcels_with_Ownership_Groups.csv") %>%
  group_by(OWNER_NAME_1) %>%
  summarise() %>%
  # match to WDFI records by name
  left_join(wdfi.current %>%
              select(corp_name_clean, wdfi_id, registered_agent, address_city),
            by = c("OWNER_NAME_1" = "corp_name_clean"))

# WDFI registrations of landlords from the MPROP file
wdfi.mprop.matches <- wdfi.current %>%
  filter(! address_city %in% wdfi.addresses.not.useful$address_city,
         corp_name_clean %in% mprop.owners$OWNER_NAME_1)

# these *current* WDFI records are matched to an MPROP owner name OR they have the registered agent AND address of an MPROP match
#   AND they don't have the address of a useless registered agent
wdfi.mprop.connected <- wdfi.current %>%
  filter(address_city %in% wdfi.mprop.matches$address_city,
         registered_agent %in% wdfi.mprop.matches$registered_agent) %>%
  # corp_names must be unique per WI law. Sometimes a corp has multiple entries, 
  #   apparently due to reorganization. This code just keeps the entry with the
  #   most recent status update
  group_by(corp_name_clean) %>%
  slice_max(status_date, n = 1, with_ties = F) %>%
  ungroup() %>%
  select(wdfi_id, registered_agent, address_city)

wdfi.mprop.connected %>%
  filter(registered_agent == "TABITHA PERRY")

# don't use these addresses to merge because they don't indicate a real connection
no.merge.addresses <- readxl::read_excel("data/munges/WDFI_notes.xlsx", sheet = 2) %>%
  mutate(address_city = str_replace_all(address_city, "\\s", " "))

# returns a list of names connected by address/name network to the given name
agent_group_names <- function(x, d=wdfi.mprop.connected) {
  # obtain all the names sharing an address with the first name
  m <- merge(d, d[d$registered_agent %in% x, c("address_city")]) %>%
    filter(! address_city %in% no.merge.addresses$address_city) %>%
    pull(registered_agent) %>% unique()
  
  # run the function recursively until the output is the same length as the output
  if (identical(length(m), length(x))) {
    return(x)
  } else {
    agent_group_names(m, d)
  }
}

# returns a tibble of the corporations registered to the agent_group
agent_group_corps <- function(agent_names, d = wdfi.mprop.connected){
    agent.group.corps <- d %>%
      select(wdfi_id, registered_agent) %>%
      filter(registered_agent %in% agent_names) %>%
      # if multiple names, name ownership group after the most frequent OWNER_NAME_1 value
      mutate(agent_group_name = if_else(length(agent_names) > 1,
                                        true = paste(names(which.max(table(registered_agent))), "Group"),
                                        false = first(registered_agent)))
    
    agent.group.corps
}

# demo
agent_group_names("SHANE ZOLPER") %>%
  agent_group_corps()



# owner names which haven't yet been assigned a group
# this object will be updated as the function runs
agent.names.without.agent.group <- wdfi.mprop.connected %>%
  group_by(registered_agent) %>%
  summarise() %>%
  ungroup()

# use this function to cycle through all owner names, removing the ones that have
#   already been assigned an owner group
return_agent_group <- function(agent_name){
  unmatched.corps <- wdfi.mprop.connected %>% filter(registered_agent %in% agent.names.without.agent.group$registered_agent)
  connected.agent.names <- agent_group_names(agent_name,
                                             d = unmatched.corps)
  
  # update the external object with the list of owner names that haven't been assigned a group
  updated.names.wthout.agent.group <- agent.names.without.agent.group %>%
    filter(! registered_agent %in% connected.agent.names)
  assign("agent.names.without.agent.group", updated.names.wthout.agent.group,
         envir = .GlobalEnv)
  
  agent_group_corps(connected.agent.names,
                    d = unmatched.corps)
}

# this line takes ~2 minutes to run
all.agent.groups <- map_df(agent.names.without.agent.group$registered_agent,
                           return_agent_group, .progress = T)

agent.group.totals <- all.agent.groups %>%
  group_by(agent_group_name) %>%
  summarise(agents = n_distinct(registered_agent),
            entites = n(),
            agent_names = paste(unique(registered_agent), collapse = "; "))

all.agent.groups.final <- wdfi.current %>%
  select(wdfi_id, corp_name_clean, address_city) %>%
  inner_join(all.agent.groups) %>%
  mutate(corp_mprop_match = corp_name_clean %in% mprop.owners$OWNER_NAME_1) %>%
  rename(agent_name = registered_agent, agent_address = address_city,
         agent_group = agent_group_name)
write_csv(all.agent.groups.final, "data/wdfi/wdfi_agent_groups.csv")
