rm(list = ls())

library(tidyverse)

wdfi.1col <- vroom::vroom("data/wdfi/WDFI_PrincipalAddress.txt", delim = "::",
                          col_names = F) %>%
  mutate(comma_count = str_count(X1, ","))

wdfi.1col %>%
  group_by(comma_count) %>%
  summarise(n = n()) %>%
  mutate(pct = (n/sum(n))*100)

wdfi.names <- str_split(wdfi.1col$X1[[1]], ",")[[1]]

wdfi.17 <- wdfi.1col %>%
  filter(comma_count == 17) %>%
  separate(col = X1, into = wdfi.names, sep = ",") %>%
  filter(EntityID != "EntityID")


wdfi.18.1 <- wdfi.1col %>%
  filter(comma_count == 18) %>%
  separate(col = X1, into = c(wdfi.names, "extra"), sep = ",") %>%
  filter(EntityType %in% unique(wdfi.17$EntityStatus))

wdfi.18.2 <- wdfi.1col %>%
  filter(comma_count == 18) %>%
  separate(col = X1, into = c(wdfi.names[1:2], "extra", wdfi.names[3:18]), sep = ",") %>%
  filter(EntityID %in% wdfi.18.1$EntityID) %>%
  mutate(EntityName = paste(EntityName, extra)) %>%
  select(-extra)

(nrow(wdfi.17) + nrow(wdfi.18.2)) / nrow(wdfi.1col)


wdfi.processed <- bind_rows(wdfi.17, wdfi.18.2)
write_csv(wdfi.processed, "data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz")
