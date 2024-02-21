defmodule WhoOwnsWhat.Data.Import do
  alias WhoOwnsWhat.Repo
  alias WhoOwnsWhat.Data.{Property, OwnerGroup, OwnerGroupProperty}

  @path Application.compile_env(:who_owns_what, :data_folder_path)
  @external_resource Path.join(@path, "LandlordProperties-with-OwnerNetworks.csv")
  @external_resource Path.join(@path, "Landlord-network-summary-statistics.csv")

  @data File.read!(Path.join(@path, "LandlordProperties-with-OwnerNetworks.csv"))
        |> :zlib.gzip()
  @summary_data File.read!(Path.join(@path, "Landlord-network-summary-statistics.csv"))
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

      property =
        %{
          taxkey: Map.fetch!(map, "TAXKEY"),
          convey_date: convert_string_maybe_na_to_date(Map.fetch!(map, "CONVEY_DATE")),
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
          owner_address: String.replace_suffix(Map.fetch!(map, "mprop_address"), "_mprop", ""),
          owner_city_state: Map.fetch!(map, "OWNER_CITY_STATE"),
          owner_zip_code: Map.fetch!(map, "OWNER_ZIP"),
          geo_zip_code: Map.fetch!(map, "GEO_ZIP_CODE"),
          calculated_owner_occupied: Map.fetch!(map, "owner_occupied") == "OWNER OCCUPIED",
          owner_occupied: Map.fetch!(map, "OWN_OCPD") != "NA",
          geo_alder: Map.fetch!(map, "GEO_ALDER"),
          wdfi_address: String.replace_suffix(Map.fetch!(map, "wdfi_address"), "_wdfi", ""),
          inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
          updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
          dns_covered_days:
            convert_string_maybe_na_to_integer(Map.fetch!(map, "dns_covered_days")),
          dns_covered_unit_years:
            convert_string_maybe_na_to_float(Map.fetch!(map, "dns_covered_unit_years")),
          total_dns_orders: String.to_integer(Map.fetch!(map, "total_orders")),
          total_dns_violations: String.to_integer(Map.fetch!(map, "total_violations")),
          ownership_dns_orders: String.to_integer(Map.fetch!(map, "ownership_orders")),
          ownership_dns_violations: String.to_integer(Map.fetch!(map, "ownership_violations")),
          eviction_orders: convert_string_maybe_na_to_integer(Map.fetch!(map, "evict_orders")),
          eviction_filings: convert_string_maybe_na_to_integer(Map.fetch!(map, "evict_filings"))
        }
        |> Map.update!(:wdfi_address, fn address ->
          if address == "NA" do
            nil
          else
            address
          end
        end)

      {map, property}
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn maps_properties ->
      {maps, properties} =
        Enum.reduce(maps_properties, {[], []}, fn {map, property}, {maps, properties} ->
          {[map | maps], [property | properties]}
        end)

      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:insert_all, Property, properties)
        |> Repo.transaction()

      maps
    end)
    |> List.flatten()
  end

  def ownership_groups(maps) do
    Stream.map(maps, fn map ->
      %{
        taxkey: Map.fetch!(map, "TAXKEY"),
        owner_group_name: Map.fetch!(map, "final_group"),
        wdfi_group_id: Map.fetch!(map, "component_number"),
        # group_source: Map.fetch!(map, "final_group_source"),
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
    owner_groups =
      @summary_data
      |> :zlib.gunzip()
      |> String.trim()
      |> String.split("\n")

    keys =
      owner_groups
      |> Enum.take(1)
      |> hd()
      |> String.trim()
      |> String.split(",")

    owner_groups
    |> Stream.drop(1)
    |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
    |> Stream.map(fn values ->
      map =
        List.zip([keys, values])
        |> Enum.into(%{})

      annual_evict_filing_rate_per_unit =
        convert_string_maybe_na_to_float(Map.fetch!(map, "annual_evict_filing_rate_per_unit"))

      annual_evict_order_rate_per_unit =
        convert_string_maybe_na_to_float(Map.fetch!(map, "annual_evict_order_rate_per_unit"))

      ownership_dns_violation_unit_rate_annual =
        convert_string_maybe_na_to_float(Map.fetch!(map, "ownership_violation_unit_rate_annual"))

      evict_covered_unit_years =
        convert_string_maybe_na_to_float(Map.fetch!(map, "evict_covered_unit_years"))

      owner_group =
        %{
          name: Map.fetch!(map, "final_group"),
          number_properties: String.to_integer(Map.fetch!(map, "parcels")),
          number_units: String.to_integer(Map.fetch!(map, "units")),
          total_assessed_value: String.to_integer(Map.fetch!(map, "total_assessed_value")),
          # wdfi_group_id: Map.fetch!(map, "component_number"),
          # names: Map.fetch!(map, "names"),
          # name_count: Map.fetch!(map, "name_count"),
          eviction_orders: convert_string_maybe_na_to_integer(Map.fetch!(map, "evict_orders")),
          eviction_filings: convert_string_maybe_na_to_integer(Map.fetch!(map, "evict_filings")),
          eviction_covered_unit_years: evict_covered_unit_years,
          annual_eviction_filing_rate_per_unit: annual_evict_filing_rate_per_unit,
          annual_eviction_order_rate_per_unit: annual_evict_order_rate_per_unit,
          dns_covered_unit_years:
            Float.parse(Map.fetch!(map, "dns_covered_unit_years")) |> elem(0),
          ownership_dns_orders: String.to_integer(Map.fetch!(map, "ownership_orders")),
          ownership_dns_violations: String.to_integer(Map.fetch!(map, "ownership_violations")),
          ownership_dns_violation_unit_rate_annual: ownership_dns_violation_unit_rate_annual,
          total_dns_orders: String.to_integer(Map.fetch!(map, "total_orders")),
          total_dns_violations: String.to_integer(Map.fetch!(map, "total_violations")),
          inserted_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second),
          updated_at: NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)
        }

      owner_group
    end)
    |> Stream.chunk_every(500)
    |> Enum.map(fn owner_group_maps ->
      {:ok, _} =
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(:insert_all, OwnerGroup, owner_group_maps)
        |> Repo.transaction()
    end)
  end

  defp convert_string_maybe_na_to_float("NA"), do: nil
  defp convert_string_maybe_na_to_float("0"), do: 0.0

  defp convert_string_maybe_na_to_float(string_number) do
    {float, ""} = Float.parse(string_number)
    float
  end

  defp convert_string_maybe_na_to_integer("NA"), do: nil
  defp convert_string_maybe_na_to_integer("0"), do: 0

  defp convert_string_maybe_na_to_integer(string_number) do
    String.to_integer(string_number)
  end

  defp convert_string_maybe_na_to_date("NA"), do: nil

  defp convert_string_maybe_na_to_date(string_date) do
    NaiveDateTime.from_iso8601!(string_date)
    |> NaiveDateTime.to_date()
  end
end
