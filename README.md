# mke-owner-networks

This repository includes data and code for identifying networks of connected landlords in the City of Milwaukee.

Currently the workflow is:

* Download and clean the MPROP file
* Clean the latest WDFI principal address file
* Identify currently-registered WDFI corporations which match an MPROP owner name
* Use MPROP names and addresses and WDFI addresses to create a final owner network

See the `/scripts/` subdirectory for more details.

The output of this process is `data/LandlordProperties-with-OwnerNetworks.csv`. This file is the basis for the website, code for which is located in the `who_owns_what` subdirectory.
