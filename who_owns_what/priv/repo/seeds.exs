# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     WhoOwnsWhat.Repo.insert!(%WhoOwnsWhat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

WhoOwnsWhat.Data.Import.properties("./data/mprop.csv.gz")
WhoOwnsWhat.Data.Import.ownership_groups("./data/parcels_ownership_groups.csv.gz")
WhoOwnsWhat.Data.Import.properties_fts()
WhoOwnsWhat.Data.Import.owner_groups()
