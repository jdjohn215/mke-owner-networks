# mke-owner-networks

This repository includes data and code for identifying networks of connected landlords in the City of Milwaukee.

## Data sources

-   MPROP - we identify all landlord-owned residential properties from city parcel data
    -   `processing-scripts/fetch-mprop.R` downloads the latest MPROP, standardizes strings, & subsets landlord properties
    -   `data/mprop/ResidentialProperties_NotOwnerOccupied.csv` contains the MPROP entry for each landlord-owned property
-   WDFI - all business incorporation records in Wisconsin
    -   `data/wdfi/20230703-220001-COMFicheX.txt` is the source file from WDFI. It is too large for github hosting, so a download link is provided.
    -   `processing-scripts/clean-wdfi-txt.R` processes the WDFI source file and creates . . .
    -   `data/WDFI_2023-07-03.csv.gz` contains the identical information from the TXT file in clean, CSV form

## Data processing (in progress)

-   MPROP ownership matching works by (1) finding all addresses shared by an owner name, (2) finding all owner name values at *those* addresses, then (3) repeating steps 1 and 2 iteratively until all matches are found.
    -   see `processing-scripts/identify-mprop-landlord-groups.R` for the code
    -   see `data/mprop/Parcels_with_Ownership_Groups.csv` for the output
-   WDFI ownership matching (not started)
