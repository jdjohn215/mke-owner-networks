## fetch-mprop.R

* retrieves the latest MPROP file from data.milwaukee.gov
* subsets landlord-owned residential properties
* basic string cleaning of owner names and addresses
* outputs `data/mprop/ResidentialProperties_NotOwnerOccupied.csv`

## mprop-standardize-addresses.R

*	match raw owner addresses against list of raw addresses previously standardized by geocodio
*	run new addresses thru geocodio
*	update standardized address table
*	outputs `data/mpropResidentialProperties_NotOwnerOccupied_StandardizedAddresses`.csv

## Process-WDFI-Principal-Address.R

* cleans the original principal address txt file from WDFI
* subsets those records where the principal office address is extractable
* outputs `data/wdfi/WDFI_PrincipalAddress_Processed.csv.gz`

## subset-current-wdfi.R

* cleans the processed WDFI principal address file
* standardizes strings
* subsets only currently registered corporations
* subsets only corporations appearing in MPROP
* outputs `data/wdfi/wdfi-current-in-mprop.csv`

## wdfi-standardize-addresses.R

*	Match raw principal & agent addresses against list of raw addresses previously standardized
*	Run new addresses thru geocodio
*	Update standardized address table
*	Remove corporate records w/useless addresses
*	Outputs `data/wdfi/wdfi-current-in-mprop_StandardizeAddresses.csv`

## identify-owner-networks.R

* creates an owner network based on MPROP owner names, MPROP owner addresses, and WDFI principal office addresses
* uses the igraph library
* outputs `data/LandlordProperties-with-OwnerNetworks.csv`, **this is the source file for the who-owns-what website runs**
