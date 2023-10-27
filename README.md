# mke-owner-networks

This repository includes data and code for identifying networks of connected landlords in the City of Milwaukee.

Currently the workflow is:

* Download and clean the MPROP file
* Identify MPROP owner groups
* Clean the latest WDFI principal address file
* Identify WDFI corporations sharing a principal address
* Match MPROP and WDFI networks to create a final network

See the `/scripts/` subdirectory for more details.

The output of this process is `data/LandlordProperties-with-OwnerNetworks.csv`. This file is the basis for the website, code for which is located in the `who_owns_what` subdirectory.
