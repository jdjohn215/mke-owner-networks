defmodule WhoOwnsWhatWeb.HomeLive.Index do
  use WhoOwnsWhatWeb, :live_view

  @path Application.compile_env(:who_owns_what, :data_folder_path)
  @summary_data_path Path.join([@path, "overall-summary-stats.csv"])
  @external_resource @summary_data_path
  @summary_data File.read!(@summary_data_path)
                |> NimbleCSV.RFC4180.parse_string(skip_headers: true)
                |> Enum.reduce(%{}, fn [key, value], map ->
                  Map.put(map, key, value)
                end)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket, :page_title, "Milwaukee Property Ownership Network Project")
      |> assign(:total_parcels, Map.fetch!(@summary_data, "total_parcels"))
      |> assign(:total_mprop_names, Map.fetch!(@summary_data, "total_mprop_names"))
      |> assign(:total_mprop_addresses, Map.fetch!(@summary_data, "total_mprop_addresses"))
      |> assign(:total_networks, Map.fetch!(@summary_data, "total_networks"))
      |> assign(
        :pct_networks_single_parcel,
        Map.fetch!(@summary_data, "pct_networks_single_parcel")
      )
      |> assign(
        :pct_networks_multiple_names,
        Map.fetch!(@summary_data, "pct_networks_multiple_names")
      )
      |> assign(
        :pct_parcels_multiple_name_owner,
        Map.fetch!(@summary_data, "pct_parcels_multiple_name_owner")
      )
      |> assign(:mprop_updated, Map.fetch!(@summary_data, "mprop_updated"))
      |> assign(:workflow_updated, Map.fetch!(@summary_data, "workflow_updated"))
      |> assign(:wdfi_updated, Map.fetch!(@summary_data, "wdfi_updated"))
      |> assign(:evict_start, Map.fetch!(@summary_data, "evict_start"))
      |> assign(:evict_end, Map.fetch!(@summary_data, "evict_end"))
      |> assign(:dns_start, Map.fetch!(@summary_data, "dns_start"))
      |> assign(:dns_end, Map.fetch!(@summary_data, "dns_end"))

    {:ok, socket}
  end
end
