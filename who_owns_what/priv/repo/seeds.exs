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
Logger.configure(level: :warning)
maps = WhoOwnsWhat.Data.Import.properties()
WhoOwnsWhat.Data.Import.ownership_groups(maps)
WhoOwnsWhat.Data.Import.properties_fts()
WhoOwnsWhat.Data.Import.owner_groups()
Logger.configure(level: :debug)
