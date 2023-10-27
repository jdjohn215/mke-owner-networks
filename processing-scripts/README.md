## fetch-mprop.R

* retrieves the latest MPROP file from data.milwaukee.gov
* subsets landlord-owned residential properties
* basic string cleaning of owner names and addresses
* outputs `data/mprop/ResidentialProperties_NotOwnerOccupied.csv`

## identify-mprop-landlord-groups.R

* uses recursive matching to identify mprop owner groups
* outputs `data/mprop/Parcels_with_Ownership_Groups.csv`

## Process-WDFI-Principal-Address.R

* cleans the original principal address txt file from WDFI
* subsets those records where the principal office address is extractable
* outputs `data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz`

## subset-current-wdfi.R

* cleans the processed WDFI principal address file
* standardizes strings
* subsets only currently registered corporations
* outputs `data/wdfi/WDFI_Current_2023-10-09.csv.gz`

## identify-wdfi-agent-groups.R

* matches WDFI records to MPROP owner names
* creates networks of WDFI names connected by address
* outputs `data/wdfi/wdfi_agent_groups.csv`

## Combine-mprop-and-landlord-networks.R

* combines the MPROP and WDFI networks
* creates unified final owner network
* outputs `data/LandlordProperties-with-OwnerNetworks.csv`, **this is the source file for the who-owns-what website runs**
