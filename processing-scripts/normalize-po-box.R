library(tidyverse)

# PO box normalization shared by mprop-standardize-addresses.R and
#   wdfi-standardize-addresses.R, so a PO box is written the same way in both
#   address caches. Expects uppercased addresses.
normalize_po_box <- function(x) {
  x %>%
    str_replace_all("P[.]O[.]|P[.] O[.]|P[.]0[.]", "PO") %>%
    str_replace_all("P[.]O ", "PO ") %>%
    # any spelling of PO BOX: "P O BOX", "POBOX", "P0 BOX"
    str_replace_all("\\bP\\s*\\.?\\s*[O0]\\s*\\.?\\s*BOX\\b", "PO BOX") %>%
    # box number written first ("26233 PO BOX, ...") when nothing follows the box
    str_replace("^(\\d+)\\s+PO BOX(?=\\s*(,|$))", "PO BOX \\1") %>%
    str_replace_all("\\bPO BOX\\s*#\\s*", "PO BOX ") %>%
    # USPS drops leading zeros from box numbers ("PO BOX 04313" -> "PO BOX 4313")
    str_replace_all("\\bPO BOX\\s+0+(?=\\d)", "PO BOX ")
}

# Milwaukee's MLK Drive in its USPS name; geocodio returns several aliases
#   ("N MLK DR", "MARTIN LUTHER KING JR DR", ...)
normalize_mlk <- function(x) {
  str_replace(x, "^(\\S+) (?:N )?(?:DR )?(?:MARTIN LUTHER KING|MLK)(?: JR)? DR\\b(?=.*, MILWAUKEE, WI 532)",
              "\\1 N DR MARTIN LUTHER KING JR DR")
}
