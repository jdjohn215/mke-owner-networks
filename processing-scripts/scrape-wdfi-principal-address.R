rm(list = ls())

library(tidyverse)
library(rvest)

wdfi <- vroom::vroom("data/wdfi/WDFI_Current_2023-07-03.csv.gz")

# construct the URL for the WDFI search page
build_url <- function(corp_name){
  paste0(
    "https://www.wdfi.org/apps/corpsearch/Results.aspx?type=Simple&q=",
    str_replace_all(URLencode(corp_name), "%20", "+")
  )
}

# e.g.
build_url(wdfi$corp_name[50])

# this function:
#   1. visits the search page
#   2. scrapes the corp URL
#   3. visits the corp page
#   4. scrapes the corp principal address
get_principal_address <- function(corp_name){
  wdfi.search.page <- read_html(build_url(corp_name))
  wdfi.corp.url <- wdfi.search.page %>%
    html_node(".nameAndTypeDescription") %>%
    html_node("a") %>%
    html_attr("href")
  
  wdfi.corp.page <- read_html(paste0("https://www.wdfi.org/apps/corpsearch/",
                                     wdfi.corp.url))
  wdfi.corp.addresses <- wdfi.corp.page %>%
    html_node("#entityDetails") %>%
    html_nodes("address") %>%
    html_text() %>%
    str_squish()
  wdfi.corp.addresses[2]
}

# e.g.
get_principal_address(wdfi$corp_name[5000])
