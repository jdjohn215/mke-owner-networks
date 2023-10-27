## fetch-mprop.R

* retrieves the latest MPROP file from data.milwaukee.gov
* subsets landlord-owned residential properties
* basic string cleaning of owner names and addresses
* outputs `data/mprop/ResidentialProperties_NotOwnerOccupied.csv`

## Process-WDFI-Principal-Address.R

* cleans the original principal address txt file from WDFI
* subsets those records where the principal office address is extractable
* outputs `data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz`

## subset-current-wdfi.R

* cleans the processed WDFI principal address file
* standardizes strings
* subsets only currently registered corporations
* outputs `data/wdfi/WDFI_Current_2023-10-09.csv.gz`

## subset-mprop-connected-wdfi.R

* keeps current WDFI records that are connected to an MPROP owner by name
* removes those WDFI records with an address deemed useless because it doesn't represent real connections
* outputs `data/wdfi/wdfi-connected-to-mprop.csv`

## identify-owner-networks.R

* creates an owner network based on MPROP owner names, MPROP owner addresses, and WDFI principal office addresses
* uses the igraph library
* outputs `data/LandlordProperties-with-OwnerNetworks.csv`, **this is the source file for the who-owns-what website runs**
