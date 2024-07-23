defmodule WhoOwnsWhatWeb.PageController do
  use WhoOwnsWhatWeb, :controller
  alias WhoOwnsWhat.Data

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def owner_groups_csv(conn, %{"id" => id}) do
    og = Data.get_owner_group_by_name_with_properties!(id)

    headers = [
      :taxkey,
      :house_number_low,
      :house_number_high,
      :house_number_suffix,
      :street,
      :street_direction,
      :street_type,
      :number_units,
      :land_use_gp,
      :c_a_total,
      :convey_date,
      :geo_alder,
      :geo_zip_code,
      :owner_address,
      :owner_name_1,
      :owner_name_2,
      :owner_name_3,
      :zoning,
      :wdfi_address,
      :dns_covered_days,
      :dns_covered_unit_years,
      :total_dns_orders,
      :total_dns_violations,
      :ownership_dns_orders,
      :ownership_dns_violations,
      :eviction_filings,
      :eviction_orders,
      :latitude,
      :longitude
    ]

    rows =
      Enum.map(og.properties, fn property ->
        [
          property.taxkey,
          property.house_number_low,
          property.house_number_high,
          property.house_number_suffix,
          property.street,
          property.street_direction,
          property.street_type,
          property.number_units,
          property.land_use_gp,
          property.c_a_total,
          property.convey_date,
          property.geo_alder,
          property.geo_zip_code,
          property.owner_address,
          property.owner_name_1,
          property.owner_name_2,
          property.owner_name_3,
          property.zoning,
          property.wdfi_address,
          property.dns_covered_days,
          property.dns_covered_unit_years,
          property.total_dns_orders,
          property.total_dns_violations,
          property.ownership_dns_orders,
          property.ownership_dns_violations,
          property.eviction_filings,
          property.eviction_orders,
          property.latitude,
          property.longitude
        ]
      end)

    csv_data = NimbleCSV.RFC4180.dump_to_iodata([headers | rows])

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"download.csv\"")
    |> put_root_layout(false)
    |> send_resp(200, csv_data)
  end
end
