rm(list = ls())

library(tidyverse)

wdfi <- vroom::vroom("data/wdfi/corpdata results Marquette_fixed.txt")

wdfi.processed <- wdfi
write_csv(wdfi.processed, "data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz")
