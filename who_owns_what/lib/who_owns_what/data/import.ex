defmodule WhoOwnsWhat.Data.Import do
  alias WhoOwnsWhat.Repo
  alias WhoOwnsWhat.Data.Property
  alias WhoOwnsWhat.Data.OwnerGroupProperty

  @path Application.compile_env(:who_owns_what, :data_folder_path)
  @external_resource Path.join(@path, "LandlordProperties-with-OwnerNetworks.csv")

  @data File.read!(Path.join(@path, "LandlordProperties-with-OwnerNetworks.csv"))
         |> :zlib.gzip()

  def properties do
    properties =
      @data
      |> :zlib.gunzip()
      |> String.trim()
      |> String.split("\n")

    keys =
      properties
      |> Enum.take(1)
      |> hd()
      |> String.trim()
      |> String.split(",")

    properties
    |> Stream.drop(1)
    |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
    |> Stream.map(fn values ->
      map =
        List.zip([keys, values])
        |> Enum.into(%{})

      property = %{
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
        owner_name_1: Map.fetch!(map, "mprop_name"),
        owner_name_2: Map.fetch!(map, "OWNER_NAME_2"),
        owner_name_3: Map.fetch!(map, "OWNER_NAME_3"),
        owner_address: Map.fetch!(map, "mprop_address"),
        # owner_city_state: Map.fetch!(map, "OWNER_CITY_STATE"),
        # owner_zip_code: Map.fetch!(map, "OWNER_ZIP"),
        geo_zip_code: Map.fetch!(map, "GEO_ZIP_CODE"),
        calculated_owner_occupied: Map.fetch!(map, "owner_occupied") == "OWNER OCCUPIED",
        # owner_occupied: Map.fetch!(map, "OWN_OCPD") != "NA",
        geo_alder: Map.fetch!(map, "GEO_ALDER"),
        wdfi_address: Map.fetch!(map, "wdfi_address"),
        inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
        updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)
      }

      {map, property}
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn maps_properties ->
      {maps, properties} = Enum.reduce(maps_properties, {[], []}, fn({map, property}, {maps, properties}) ->
        {[map | maps], [property | properties]}
      end)
      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:insert_all, Property, properties)
        |> Repo.transaction()

      maps
    end)
    |> List.flatten
  end

  def ownership_groups(maps) do
    Stream.map(maps, fn map ->
      %{
        taxkey: Map.fetch!(map, "TAXKEY"),
        owner_group_name: Map.fetch!(map, "final_group"),
        wdfi_group_id: Map.fetch!(map, "wdfi_group_id"),
        group_source: Map.fetch!(map, "final_group_source"),
        inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
        updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)
      }
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn owner_groups_properties ->
      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:insert_all, OwnerGroupProperty, owner_groups_properties)
        |> Repo.transaction()
    end)
  end

  def properties_fts do
    Ecto.Adapters.SQL.query!(
      Repo,
      """
      INSERT INTO properties_fts (rowid, taxkey, owner_name_1, full_address, owner_group_name)
      SELECT p.id, p.taxkey, owner_name_1,
        house_number_low || ' ' ||  house_number_high || ' ' || street_direction || ' ' || street || ' ' || street_type || ' ' || geo_zip_code,
      ogp.owner_group_name
      FROM properties p
      JOIN owner_groups_properties ogp on ogp.taxkey = p.taxkey
      """
    )
  end

  def owner_groups do
    Ecto.Adapters.SQL.query!(
      Repo,
      """
      INSERT INTO owner_groups (name, number_properties, number_units, inserted_at, updated_at)
      SELECT owner_group_name, count(number_units), sum(number_units), datetime('now'), datetime('now')
      FROM properties p
      JOIN owner_groups_properties ogp on ogp.taxkey = p.taxkey
      GROUP BY ogp.owner_group_name
      """
    )
  end
end
