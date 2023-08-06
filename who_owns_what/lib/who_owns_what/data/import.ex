defmodule WhoOwnsWhat.Data.Import do
  alias WhoOwnsWhat.Repo
  alias WhoOwnsWhat.Data.Property
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  @external_resource "data/mprop.csv.gz"
  @external_resource "data/parcels_ownership_groups.csv.gz"
  @mprop File.read!("data/mprop.csv.gz")
  @owner File.read!("data/parcels_ownership_groups.csv.gz")

  def properties(_path) do
    mprop = @mprop
            |> :zlib.gunzip()
            |> String.trim()
            |> String.split("\n")
    keys =
      mprop
      |> Enum.take(1)
      |> hd()
      |> String.trim()
      |> String.split(",")

    mprop
    |> Stream.drop(1)
    |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
    |> Stream.map(fn values ->
      map =
        List.zip([keys, values])
        |> Enum.into(%{})

      %{
        taxkey: Map.fetch!(map, "TAXKEY"),
        house_number_low: String.to_integer(Map.fetch!(map, "HOUSE_NR_LO")),
        house_number_high: String.to_integer(Map.fetch!(map, "HOUSE_NR_HI")),
        house_number_suffix: Map.fetch!(map, "HOUSE_NR_SFX"),
        street_direction: Map.fetch!(map, "SDIR"),
        street: Map.fetch!(map, "STREET"),
        street_type: Map.fetch!(map, "STTYPE"),
        c_a_class: Map.fetch!(map, "C_A_CLASS"),
        land_use_gp: Map.fetch!(map, "LAND_USE_GP"),
        c_a_total: String.to_integer(Map.fetch!(map, "C_A_TOTAL")),
        number_units: String.to_integer(Map.fetch!(map, "NR_UNITS")),
        owner_name_1: Map.fetch!(map, "OWNER_NAME_1"),
        owner_name_2: Map.fetch!(map, "OWNER_NAME_2"),
        owner_name_3: Map.fetch!(map, "OWNER_NAME_3"),
        owner_address: Map.fetch!(map, "OWNER_MAIL_ADDR"),
        owner_city_state: Map.fetch!(map, "OWNER_CITY_STATE"),
        owner_zip_code: Map.fetch!(map, "OWNER_ZIP"),
        geo_zip_code: Map.fetch!(map, "GEO_ZIP_CODE"),
        calculated_owner_occupied: Map.fetch!(map, "owner_occupied") == "OWNER OCCUPIED",
        owner_occupied: Map.fetch!(map, "OWN_OCPD") != "NA",
        geo_alder: Map.fetch!(map, "GEO_ALDER"),
        inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
        updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)
      }
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn properties ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:insert_all, Property, properties)
      |> Repo.transaction()
    end)
  end

  def ownership_groups(_path) do
    owner = @owner
            |> :zlib.gunzip()
            |> String.trim()
            |> String.split("\n")
    keys =
      owner
      |> Enum.take(1)
      |> hd()
      |> String.trim()
      |> String.split(",")

    owner
    |> Stream.drop(1)
    |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
    |> Stream.map(fn values ->
      map =
        List.zip([keys, values])
        |> Enum.into(%{})

      %{
        taxkey: Map.fetch!(map, "TAXKEY"),
        name: Map.fetch!(map, "owner_group_name"),
        inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
        updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)
      }
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn owner_groups_properties ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:insert_all, OwnerGroupProperty, owner_groups_properties)
      |> Repo.transaction()
    end)
  end

  def properties_fts do
    Ecto.Adapters.SQL.query!(
      Repo,
      """
      INSERT INTO properties_fts (rowid, taxkey, owner_name_1, full_address, owner_group)
      SELECT p.id, p.taxkey, owner_name_1,
        house_number_low || ' ' ||  house_number_high || ' ' || street_direction || ' ' || street || ' ' || street_type || ' ' || geo_zip_code,
      ogp.name
      FROM properties p
      JOIN owner_groups_properties ogp on ogp.taxkey = p.taxkey
      """
    )
  end
end
